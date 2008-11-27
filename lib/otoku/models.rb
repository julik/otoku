module Otoku::Models
  class MakeBasics < V 1.0
    
    def self.up
      create_table :otoku_archives do | a |
        a.string :name
        a.datetime :creation
        a.string :appstring
        a.string :comment
        a.string :device
        a.string :etag
      end
      
      create_table :otoku_entries do | e |
        e.integer :archive_id
        e.integer :index_in_parent
        e.string :classid
        e.string :flameid, :maxlength => 100
        e.string :name
        e.integer :duration
        e.string :description
        e.datetime :creation
        e.integer :width
        e.integer :height
        e.integer :length
        e.string :depth
        e.string :image1
        e.string :image2
        
        e.integer :index_in_parent
        
        # acts_as_nested_set cols
        e.integer :lft
        e.integer :rgt
        e.integer :parent_id
        e.integer :depth
      end
    end

    def self.down
      %w(otoku_archives otoku_entries).map{|t| drop_table t }
    end
  end

  class Archive < Base
    include Otoku::Data::ModelMethods::ArchiveMethods
    include Otoku::Data::ModelMethods::EntryKey
    
    has_many :entries, :class_name => 'Otoku::Models::Entry'
    
    def child_by_id(key)
      entries.find(:first, :conditions => {:flameid => key})
    end
    
    def entries
      Entry.find(:all, :conditions => {:parent_id => nil})
    end
    
    def  [](key)
      key.is_a?(Integer) ? entries[key] : super(key)
    end
  end
  
  class Entry < Base
    belongs_to :archive, :class_name => 'Otoku::Models::Archive'
    # Pass :text_column to prevent the plugin from querying the DB before the connection is live
    acts_as_nested_set :text_column => :name, :scope => :archive_id

    include Otoku::Data::ModelMethods::EntryMethods
    include Otoku::Data::ModelMethods::EntryKey
    
    def entries
      children
    end
    
    def  [](key)
      key.is_a?(Integer) ? entries[key] : super(key)
    end
    
    def path
      (ancestors + [self]).map(&:index_in_parent).join('/')
    end 
  end
end