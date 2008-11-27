module Otoku
module Data
  PATH_SEPARATOR = '/'
  
  module ModelMethods
    module Ordinals
      def [](idx)
        idx.is_a?(Integer) ? entries[idx] : super(idx)
      end
    end
    
    module EntryKey
      def child_by_id(clip_key)
        entries.each do | e |
          return e if e.id == clip_key
          match = e.child_by_id(clip_key)
          return match if match
        end
        nil
      end
      
      # Get a child element by scanning per index. Groups of integers are considered indices.
      # get_by_path("0:1:0") # => get the first child of the second child of the first child
      def get_by_path(index_path)

        # Prevent string ops
        index_path = index_path.scan(/\d+/).to_a.map{|e| e.to_i } if index_path.is_a?(String)
        
        cur = index_path.shift
        raise "Overflow" if (cur < 0 || cur >= entries.length)
         
        index_path.empty? ? entries[cur] : entries[cur].get_by_path(index_path)
      end

    end
     
    module ArchiveMethods
      def dir
        File.dirname(path)
      end

      # Given a path of clip IDs will drill down into the entries hierarchy and fetch the entry requested.
      def fetch_uri(clip_path)
        self[clip_path.split(/#{Regexp.escape(PATH_SEPARATOR)}/).pop]
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
      
      def desktop?
        classid == 'D'
      end

      def has_icon?
        clip? || subclip?
      end
      
      def length
        clip? ? duration : entries.length
      end
      
      def uri
        subclip? ? [parent.id, index_in_parent].join('/') : id
      end
      
      
      def parent_chain
        return @parent_chain if @parent_chain
        
        cur, chain = self, []
        while cur.respond_to?(:parent) do
          chain.unshift(cur)
          cur = cur.parent
        end
        @parent_chain = chain
      end
      
      def path
        File.join(parent_chain.map{|e| (e.etag rescue e.index_in_parent).to_s })
      end
      
      def flame_type
        case true
          when desktop?
            'Desktop'
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
          nitems = case entries.length
            when 0
              "empty"
            when 1
              "one item"
            else
              "%d items" % entries.size
          end
          
          "%s (%s) - %s" % [name, flame_type, nitems]
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
end