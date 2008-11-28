require 'digest/md5'
require 'fileutils'

module Otoku
  module Data
    class ArchiveHandle
      include Comparable
      attr_accessor :filename, :name, :creation, :manager

      def initialize; yield(self) if block_given?; end
      def <=>(other); name <=> other.name; end
      def to_s; name; end
      
      def etag
        Digest::MD5.hexdigest(filename + ':' + name)
      end
      
      def read_struct
        @manager.cache(filename) do
          data = File.read(xml_path)
          arch = Otoku::Data.parse(data)
          arch.etag = etag

          search = Otoku::Data::Search.new(@manager)
          arch.entries.each { | e | add_entry_to_index(search, e) }
          search.flush
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
      attr_reader :archives_dir, :cache
      include Enumerable
      def initialize(with_archives_dir)
        @archives_dir = File.expand_path(with_archives_dir)
        FileUtils.mkdir_p(data_dir)
        @cache = Otoku::Data::FileCache.new(data_dir)
      end
      
      def data_dir
        File.join(@archives_dir, '.otoku')
      end
      
      def cache(key)
        @cache.cached(key) do
          yield
        end
      end
      
      def scan_for_archive_handles
        files = Dir.glob(@archives_dir + '/*.xml').sort
        
        handles = files.map do | path |
          ArchiveHandle.new do | handle |
            handle.manager = self
            handle.filename = File.basename(path)
            name = File.basename(path).split(/_/)
            2.times { name.pop }
            handle.name = name.join('_')
          end
        end.uniq
      end
      
      def each
        scan_for_archive_handles.each { | handle | yield(handle) }
      end
      
      def get_searcher
        Otoku::Data::Search.new(self)
      end
      
      def read_archive(etag)
        scan_for_archive_handles.find{|h| h.etag == etag}.read_struct
      end
    end
  end
end