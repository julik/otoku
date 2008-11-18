require 'rubygems'
require 'hpricot'
require File.dirname(__FILE__) + '/model_methods'

module OTOCS
  module BlockInit
    def initialize
      yield self if block_given?
    end
  end
  
  class Archive
    include BlockInit
    include OTOCS::ModelMethods::ArchiveMethods
    include OTOCS::ModelMethods::EntryKey
    attr_accessor :entries, :name, :appstring, :creation, :device, :comment
  end
  
  class Entry
    include BlockInit
    include OTOCS::ModelMethods::EntryMethods
    include OTOCS::ModelMethods::EntryKey
    attr_accessor :classid,
      :parent,
      :id,
      :name,
      :duration,
      :height,
      :width,
      :depth,
      :image,
      :entries,
      :archive,
      :index_in_parent
  end
  
  class Device
    include BlockInit
    include OTOCS::ModelMethods::DeviceMethods
    attr_accessor :type, :name, :starts
  end
  
  def self.parse(stream)
    hpricot = Hpricot(stream)
    arch_node = hpricot / "/archive"
    
    Archive.new do | a |
      a.name = (hpricot / "/archive/name").text
      a.creation = DateTime.parse((hpricot / "/archive/creation").text)
      a.appstring = (hpricot / "/archive/appstring").text
      a.comment = (hpricot / "/archive/comment").text
      a.entries = (hpricot / "/archive/toc/entry").map do | entry_node |
        entry_from_node(entry_node, a, a)
      end
    
      a.device = Device.new do | dev |
        dev.type = (hpricot / "/archive/device/type").text
        dev.name = (hpricot / "/archive/device/name").text
        dev.starts = (hpricot / "/archive/device/starts").text
      end
    end
  end
  
  
  def self.entry_from_node(entry_node, parent, archive)
    Entry.new do | entry |
      entry.archive = archive
      entry.classid = entry_node["classid"]
      entry.id = entry_node["id"]
      entry.parent = parent
      entry.name = (entry_node / "/name").text
      entry.duration = (entry_node / "/duration").text.to_i
      entry.height = (entry_node / "/height").text.to_i
      entry.width = (entry_node / "/width").text.to_i
      entry.depth = (entry_node / "/depth").text
      entry.image = (entry_node / "/image1").text
      entry.entries = (entry_node / "/entry").map{|e| entry_from_node(e, entry, archive)}
      entry.entries.each_with_index { | e, i | e.index_in_parent = i }
    end
  end
  
end