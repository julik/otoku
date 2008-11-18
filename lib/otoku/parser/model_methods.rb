module OTOCS
  module ModelMethods
    module ArchiveMethods
      def self.included(into)
        into.send :attr_accessor, :path
        into.send :attr_accessor, :etag
        into.send :alias_method, :id, :etag
      end
      
      def entries
        toc.entries
      end

      attr_accessor :path
      attr_accessor :etag
      alias_method :id, :etag

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
    
    module DeviceMethods
      def to_s
        [type, name, starts].join(' - ')
      end
    end
    
    module EntryMethods
      def self.included(into)
        into.send(:include, OTOCS::EntryKey)
      end
      
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
        classid == 'C' || classid == 'E'
      end

      def soft_clip?
        clip? && entries.any?
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
          when soft_clip?
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
        unless subclip?
          "%s (%s) - %d items" % [name, flame_type, entries.size]
        else
          "%s" % [name]
        end
      end

      def inspect
        "#<Entry 0x%d [%s] %s (%d children)>" % [__id__, flame_type, name, entries.length]
      end
    end
  end
end