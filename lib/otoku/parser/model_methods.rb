module OTOCS
  module ModelMethods
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
     
    module ArchiveMethods

      attr_accessor :path
      attr_accessor :etag
      alias_method :id, :etag

      def dir
        File.dirname(path)
      end

      # Given a path of clip IDs will drill down into the entries hierarchy and fetch the entry requested.
      # Also assigns a backtrack object to the entry fetched so that you can get back to it
      def fetch_uri(clip_path)
        self[clip_path.split(/\//).pop]
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