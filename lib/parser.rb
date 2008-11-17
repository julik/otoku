require '/Code/happymapper/lib/happymapper'
require 'digest/md5'
require 'fileutils'

module HappyMapper::ClassMethods
  
  # For uppercase elements
  def ielement(elem, klass = String)
    element(elem, klass, :tag => elem.to_s.upcase)
  end
  
  # For uppercase attrs
  def iattribute(attr, klass = String)
    attribute(attr, klass, :tag => attr.to_s.upcase)
  end
  
  # ...for collections
  def ihas_one(*a)
    a << {:tag => a[0].to_s.upcase }
    has_one(*a)
  end

  # ...for collections
  def ihas_many(*a)
    a << {:tag => a[0].to_s.upcase }
    has_many(*a)
  end
end

module OTOCS
  
  class Device
    include HappyMapper
    tag 'DEVICE'
    iattribute :type, String
    ielement :type, String
    ielement :name, String
    ielement :starts, String # Timecode 
    def to_s
      [type, name, starts].join(' - ')
    end
  end

  module EntryKey
    def [](clip_key)
      entries.find{|e| e.id == clip_key}
    end
  end
  
  class Backtrack
    attr_accessor :archive
    attr_accessor :parents
  end
  
  class Entry
    include HappyMapper
    include EntryKey
    attr_accessor :backtrack
    
    tag 'ENTRY'
    iattribute :classid, String
    iattribute :id, String # the UUID of the reel item - very important as this is truly unique, even across machines
    
    ielement :name, String
    ielement :creation, DateTime
    ielement :duration, Integer
    ielement :audio, Boolean
    ielement :location, String
    ielement :width, Integer
    ielement :height, Integer
    ielement :depth, String
    ielement :image1, String # First image proxy
    ielement :image2, String # Last image proxy
    has_many :entries, Entry
    
    def backup_set?
      classid == '*'
    end
    
    def library?
      classid == 'L'
    end
    
    def reel?
      classid == 'R'
    end
    
    def clip?
      classid == 'C'
    end
    
    def subclip?
      classid == 'E'
    end
    
    def has_icon?
      clip? || subclip?
    end
    
    def flame_type
      case true
        when backup_set?
          'Backup Set'
        when library?
          'Library'
        when reel?
          'Reel'
        when clip? && entries.any?
          'Soft clip'
        when clip?
          'Clip'
        when subclip?
          'Subclip'
        else
          'Unknown'
      end
    end
    
    def to_s
      "%s (%s) - %d items" % [name, flame_type, entries.size]
    end
    
    def inspect
      "#<Entry 0x%d [%s] %s (%d children)>" % [__id__, flame_type, name, entries.length]
    end
  end

  class TOC
    include HappyMapper
    tag 'TOC'
    ihas_many :entries, Entry
  end
  
  # The whole archive
  class Archive
    include HappyMapper
    include EntryKey
    
    tag '/ARCHIVE' # Bug in HappyMapper requires a single slash at the start
    
    ielement :name, String
    ielement :creation, DateTime
    element :machine, String, :tag => 'appstring'.upcase
    ielement :comment, String
    ihas_one :device, Device
    ihas_one :toc, TOC
    
    def entries
      toc.entries
    end
    
    attr_accessor :path
    attr_accessor :etag
    
    def dir
      File.dirname(path)
    end
    
    
    
    def fetch_uri(clip_path)
      bt = Backtrack.new
      bt.archive = self
      bt.parents = []
      
      next_item = self
      clip_path.split(/\//).each do | seg |
        bt.parents << next_item unless next_item == self
        next_item = next_item[seg]
      end
      next_item.backtrack = bt
      next_item
    end
    
    def to_s
      "%s (%d sets)" % [name, entries.length, path]
    end
  end
  
  
  # Read an archive from +path+. Will save and/or reuse the object cache as necessary
  def self.read_archive_file(path)
    # Always contains one archive
    data = File.read(path).to_s
    cached(data) do
      arch = Archive.parse(data).pop
      arch.path, arch.etag = File.expand_path(path), Digest::MD5.hexdigest(data)
      arch
    end
  end
  
  # Set the directory used to store the preparsed OTOC structures
  def self.cache_dir=(dir)
    @cache = if dir.nil?
      nil
    else
      exp = File.expand_path(dir)
      FileUtils.mkdir_p(exp)
      exp
    end
  end

  # Get the directory used to store the preparsed OTOC structures
  def self.cache_dir
    @cache
  end
  
  private
  
  def self.cached(content)
    return yield unless @cache
    
    digest = Digest::MD5.hexdigest(content)
    path = digest.scan(/(.{2})/).join('/') + '.parsedarchive'
    cache_f = File.join(@cache, path)
    begin
      Marshal.load(File.read(cache_f))
    rescue Errno::ENOENT
      parsed = yield
      FileUtils.mkdir_p(File.dirname(cache_f))
      File.open(cache_f, 'w') { | to |  to << Marshal.dump(parsed) }
      parsed
    end
  end

  @@parsed ||= {}
  def self.cached(content)
    digest = Digest::MD5.hexdigest(content)
    @@parsed[digest] ||= yield
    @@parsed[digest]
  end
  
end