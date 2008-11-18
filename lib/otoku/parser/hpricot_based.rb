require 'rubygems'
require 'hpricot'
require File.dirname(__FILE__) + '/model_methods'

module OTOCS
  class Archive
    include OTOCS::ModelMethods::ArchiveMethods
    include OTOCS::ModelMethods::EntryKey
    attr_accessor :entries, :name, :appstring, :creation, :machine
  end
  
  class Entry
    include OTOCS::ModelMethods::EntryMethods
    attr_accessor :classid,
      :parent,
      :id,
      :name,
      :duration,
      :height,
      :width,
      :depth,
      :image,
      :entries
  end
  
  class Device
    include OTOCS::ModelMethods::DeviceMethods
    attr_accessor :type, :name, :starts
  end
  
  def self.parse(stream)
    hpricot = Hpricot(stream)
    
    arch_node = hpricot / "/archive"
    
    arch = Archive.new
    arch.name = (hpricot / "/archive/name").text
    arch.creation = DateTime.parse((hpricot / "/archive/creation").text)
    arch.appstring = DateTime.parse((hpricot / "/archive/appstring").text)
    
    arch.entries = (hpricot / "/archive/toc/entry").map do | entry_node |
      entry_from_node(entry_node, arch)
    end
    
    arch.machine = Device.new
    arch.machine.type = (hpricot / "/archive/device/type").text
    arch.machine.name = (hpricot / "/archive/device/name").text
    arch.machine.starts = (hpricot / "/archive/device/starts").text
    
    arch
  end
  
  
  def self.entry_from_node(entry_node, parent)
    entry = Entry.new
    entry.classid = entry_node["classid"]
    entry.id = entry_node["id"]
    entry.parent = parent
    entry.name = (entry_node / "/name").text
    entry.duration = (entry_node / "/duration").text.to_i
    entry.height = (entry_node / "/height").text.to_i
    entry.width = (entry_node / "/width").text.to_i
    entry.depth = (entry_node / "/depth").text
    entry.image = (entry_node / "/image1").text
    entry.entries = (entry_node / "/entry").map{|e| entry_from_node(e, entry)}
    
    entry
  end
  
end