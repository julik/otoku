require 'rubygems'
require 'camping'

$:.unshift File.dirname(__FILE__)
require 'otoku/parser/parser'

Camping.goes :Otoku

module Otoku
  module DataWrangler
    def get_archive_list
      OTOCS.cache_driver = OTOCS::MemoCache.new
      @archives ||= Dir.glob(File.dirname(__FILE__) + '/../test/samples/*.xml').map do | arch |
        OTOCS.read_archive_file(arch)
      end
    end
    
    def get_archive(etag)
      get_archive_list.find{|e| e.etag == etag}
    end
  end
  
  
  include DataWrangler
  module Controllers
    class Index < R '/'
      def get
        @archives = get_archive_list
        render :welcome
      end
    end
    
    class ShowEntry < R '/entry/(.+)/(.+)'
      def get(archive_etag, entry_id)
        @archive = get_archive(archive_etag)
        @item = @archive[entry_id]
        if @item.clip?
          render :clip_info
        else
          render :list_info
        end
      end
    end
    
    class ShowArchive < R '/archive/(.+)'
      def get(archive_etag)
        @archive = get_archive(archive_etag)
        @item = @archive
        render :list_info
      end
    end
    
    class ClipImage < R('/cimage/(.+)')
      def get(path)
      end
    end
  end
  
  module Views
    def list_info
      cls = @item.flame_type rescue 'archive'
      ul(:class => cls) do
        @item.entries.each {|e| _item_row(e) }
      end
    end
    
    def welcome
      h1 @archives.length.to_s + " archives in the store"
      ul do
        @archives.each do | that |
          li do
            a that, :href => R(ShowArchive, that.etag)
          end
        end
      end
    end
    
    def _item_uri(item)
      R(ShowEntry, @archive.etag, item.id)
    end
    
    def _item_row(that)
      li { a that, :href => _item_uri(that) }
    end
    
  end
end