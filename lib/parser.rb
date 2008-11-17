require '/Code/happymapper/lib/happymapper'

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
  end

  class Entry
    include HappyMapper
    tag 'ENTRY'
    iattribute :classid, String
    iattribute :id, String
    
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
    
    has_many :entries, self 
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
      classid = 'E'
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
  end

  class TOC
    include HappyMapper
    tag 'TOC'
    ihas_many :entries, Entry
  end
  
  # The whole archive
  class Archive
    include HappyMapper
    tag '/ARCHIVE' # Bug in HappyMapper requires a single slash at the start
    
    ielement :name, String
    ielement :creation, DateTime
    ielement :appstring, String
    ielement :comment, String
    ihas_one :device, Device
    ihas_one :toc, TOC
    
    def entries
      toc.entries
    end
  end
  
  def self.read_archive_file(path)
    # Always contains one archive
    Archive.parse(File.read(path).to_s).pop
  end
end


arch = OTOCS.read_archive_file('/Code/otoku/test/samples/Flame_Archive_Deel215_08Jul15_1036.xml')
puts arch.entries