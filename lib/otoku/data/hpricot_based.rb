require 'rubygems'
require 'hpricot'
require File.dirname(__FILE__) + '/model_methods'

class Otoku::HpricotParser
  class Device
    include Otoku::Data::ModelMethods::DeviceMethods
    attr_accessor :type, :name, :starts
    def initialize(type, name, starts)
      @type, @name, @starts = type, name, starts
    end
  end
  
  def new_archive(name = nil)
    returning(Otoku::Models::Archive.new) { | arch | yield(arch); arch.save! }  
  end
  
  def new_entry
    returning(Otoku::Models::Entry.new) { | entry | yield(entry); entry.save! }
  end
  
  def parse(stream)
    hpricot = Hpricot(stream)
    arch_node = hpricot / "/archive"
    
    name = (hpricot / "/archive/name").text
    new_archive(name) do | a |
      a.name = name
      a.creation = DateTime.parse((hpricot / "/archive/creation").text)
      a.appstring = (hpricot / "/archive/appstring").text
      a.comment = (hpricot / "/archive/comment").text
      
      # Before assigning child entries, save
      a.save!
      
      entries = (hpricot / "/archive/toc/entry").map do | entry_node |
        entry_from_node(entry_node, nil, a)
      end
    
      order_enum(entries)
      
      a.device = Device.new(
        (hpricot / "/archive/device/type").text,
        (hpricot / "/archive/device/name").text,
        (hpricot / "/archive/device/starts").text
      )
    end
  end
  
  def entry_from_node(entry_node, parent, archive)
    new_entry do | entry |
      assign_simple_attributes(entry, entry_node)
      entry.save!

      if parent
        parent.add_child(entry) if parent
        entry.archive_id = parent.archive_id
      elsif archive
        entry.archive_id = archive.id
      end
      
      entries = (entry_node / "/entry").map{|e| entry_from_node(e, entry, archive) }
      order_enum(entries)
    end
  end
  
  def order_enum(entries)
    entries.each_with_index {|e, i| e.update_attributes :index_in_parent => i }
  end
  
  def assign_simple_attributes(entry, entry_node)
    entry.classid = entry_node["classid"]
    entry.flameid = entry_node["id"]
    entry.name = (entry_node / "/name").text
    entry.duration = (entry_node / "/duration").text.to_i
    entry.description = (entry_node / "/description").text
    entry.creation = (entry_node / "/creation").text
    entry.height = (entry_node / "/height").text.to_i
    entry.width = (entry_node / "/width").text.to_i
    entry.depth = (entry_node / "/depth").text
    entry.length = (entry_node / "/duration").text.to_i
    entry.image1 = (entry_node / "/image1").text
    entry.image2 = (entry_node / "/image2").text
  end
end