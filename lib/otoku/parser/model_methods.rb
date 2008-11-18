module OTOCS
  module ModelMethods
    module EntryKey
       def [](clip_key)
         if clip_key.is_a?(String)
           child_by_id(clip_key)
         else
           entries[clip_key]
         end
       end
       
       def child_by_id(clip_key)
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
        [type, name, starts].reject{|e| e.nil? || e.empty? }.join(' - ')
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
        clip? && entries.size > 1
      end

      def subclip?
        classid == 'E'
      end

      def has_icon?
        clip? || subclip?
      end
      
      def uri
        subclip? ? [parent.id, index_in_parent].join('/') : id
      end
      
      def flame_type
        case true
          when backup_set?
            'BackupSet'
          when library?
            'Library'
          when reel?
            'Reel'
          when soft_clip?
            'Edit'
          when clip?
            'Clip'
          when subclip?
            'Subclip'
          else
            'Unknown'
        end
      end
      
      def to_s
        if clip? && !subclip?
          "%s (%s)" % [name, flame_type, entries.size]
        elsif !subclip?
          "%s (%s) - %d items" % [name, flame_type, entries.size]
        else
          "%s" % [name, parent.name]
        end
      end

      def inspect
        "#<Entry 0x%d [%s] %s (%d children)>" % [__id__, flame_type, name, entries.length]
      end
    end
  end
end