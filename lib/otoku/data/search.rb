module Otoku::Data::Search
  module BlockInit
    def initialize
      yield self if block_given?
    end
  end
  
  class ArchiveHandle
    include BlockInit
    include Otoku::Data::ModelMethods::ArchiveMethods
    include Otoku::Data::ModelMethods::EntryKey
    attr_accessor :entries, :name, :appstring, :creation, :device, :comment
  end
  
  class EntryHandle
    include BlockInit
    include Otoku::Data::ModelMethods::EntryMethods
    include Otoku::Data::ModelMethods::EntryKey
    attr_accessor :classid,
      :parent,
      :id,
      :name,
      :description,
      :duration,
      :creation,
      :height,
      :width,
      :depth,
      :image1,
      :image2,
      :entries,
      :archive,
      :length,
      :index_in_parent
      :entries
  end
  
  class Searcher
    def matches_criteria?(item)
    end
    
    def register(item)
      @archives ||= []
      archive_handle = item.parent_chain[0]
      handles = item.parent_chain[1..-1].map{|e| EntryHandle.new(e) }
      
      arch_handle = @archives.find{|e| e == archive_handle }
        
    end
  end
end