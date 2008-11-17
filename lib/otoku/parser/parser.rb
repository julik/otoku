require '/Code/happymapper/lib/happymapper'
require 'digest/md5'
require 'fileutils'
require File.dirname(__FILE__) + '/parser_cache'

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
      e = entries.find{|e| e.id == clip_key}
      return e if e
      deep = entries.find{|e| e[clip_key]}
      deep ? deep : nil
    end
    
  end
  
  class Backtrack
    attr_accessor :archive
    attr_accessor :parents
    def path
      ([archive.etag] + parents.collect{|e| e.id}).join('/')
    end
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
    
    # Given a path of clip IDs will drill down into the entries hierarchy and fetch the entry requested.
    # Also assigns a backtrack object to the entry fetched so that you can get back to it
    def fetch_uri(clip_path)
      bt = Backtrack.new
      bt.archive = self
      bt.parents = []
      
      next_item = self
      clip_path.split(/\//).each do | seg |
        next_item = next_item[seg]
        bt.parents << next_item unless next_item == self
      end
      next_item.backtrack = bt
      next_item
    end
    
    def to_s
      "%s (%d sets)" % [name, entries.length, path]
    end
  end
  
  class << self
    attr_accessor :cache_driver
  end
  
  
  # Read an archive from +path+. Will save and/or reuse the object cache as necessary
  def self.read_archive_file(path)
    # Always contains one archive
    data = File.read(path).to_s
    
    @cache_driver ||= OTOCS::BypassCache.new
    @cache_driver.cached(data) do
      arch = Archive.parse(data).pop
      arch.path, arch.etag = File.expand_path(path), Digest::MD5.hexdigest(data)
      arch
    end
  end
  
end