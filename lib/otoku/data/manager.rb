require 'digest/md5'
require 'fileutils'
module Otoku
  module Data
    class ArchiveHandle
      include Comparable
      
      attr_accessor :filename, :name, :creation, :manager

      def initialize(path, manager)
        @manager = manager
        @filename = File.basename(path)
        
        split = File.basename(path).split(/_/)
        @name = split[0..-3].join('_')
        @creation = DateParser.parse(File.basename(path))
        
        yield(self) if block_given?
      end

      def <=>(other)
        [name, creation] <=> [other.name, other.creation]
      end

      def to_s; name; end
      
      def etag
        Digest::MD5.hexdigest(filename + ':' + name)
      end
      
      def read_struct
        @manager.cache(filename) do
          data = File.read(xml_path)
          arch = Otoku::Data.parse(data)
          arch.etag = etag
          
          s = Otoku::Data::Search.new(@manager)
          arch.entries.each { | e | add_entry_to_index(s, e) }
          s.flush
          STDERR.puts "Indexing of #{filename} complete"
          
          arch
        end
      end
      
      def full_path
        File.join(@manager.archives_dir, filename)
      end

      def xml_path
        File.join(@manager.archives_dir, filename)
      end
      
      private
        def add_entry_to_index(idx, e)
          idx.add_entry(e)
          e.entries.each{|e| add_entry_to_index(idx, e) }
        end
    end
    
    class Manager
      DATA_DIR_NAME = '.otoku'

      attr_reader :archives_dir, :cache, :handles
      delegate :empty?, :any?, :each, :length, :to => :handles
      include Enumerable
      
      def initialize(with_archives_dir)
        @archives_dir = with_archives_dir
        FileUtils.mkdir_p(data_dir)
        @cache = Otoku::Data::FileCache.new(data_dir)
        scan_for_archive_handles!
      end
      
      def data_dir
        File.join(@archives_dir, DATA_DIR_NAME)
      end
      
      def cache(key)
        @cache.cached(key) { yield }
      end
      
      
      def scan_for_archive_handles!
        files = Dir.glob(@archives_dir + '/*.xml').sort
        @handles = files.map do | path |
          ArchiveHandle.new(path, self)
        end.group_by{|a| a.name }.map do | _, same_name_handles |
          same_name_handles.sort.pop
        end
      end
      
      def read_archive(etag)
        @handles.find{|h| h.etag == etag}.read_struct
      end
    end
  end
end