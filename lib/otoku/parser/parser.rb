require '/Code/happymapper/lib/happymapper'
require 'digest/md5'
require 'fileutils'
require File.dirname(__FILE__) + '/parser_cache'
require File.dirname(__FILE__) + '/model_methods'

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
    include OTOCS::ModelMethods::DeviceMethods
    include HappyMapper
    tag 'DEVICE'
    iattribute :type, String
    ielement :type, String
    ielement :name, String
    ielement :starts, String # Timecode 
    
  end

  module EntryKey
    def [](clip_key)
      entries.each do | e |
        return e if e.id == clip_key
        match = e[clip_key]
        return match if match
      end
      nil
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
    include OTOCS::ModelMethods::EntryMethods
    
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
        
  end

  class TOC
    include HappyMapper
    tag 'TOC'
    ihas_many :entries, Entry
  end
  
  # The whole archive
  class Archive
    include OTOCS::ModelMethods::ArchiveMethods
    
    include HappyMapper
    include EntryKey
    
    tag '/ARCHIVE' # Bug in HappyMapper requires a single slash at the start
    
    ielement :name, String
    ielement :creation, DateTime
    element :machine, String, :tag => 'appstring'.upcase
    ielement :comment, String
    ihas_one :device, Device
    ihas_one :toc, TOC
    
    
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