require 'rubygems'
require 'camping'
require File.dirname(__FILE__) + '/parser/parser'

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
        @item = @archive.get_entry(entry_id)
        if @item.clip?
          render :clip_info
        else
          render :list_info
        end
      end
    end
    
    class ShowArchive < R '/entry/(.+)'
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
      ul :class => @item.flame_type do
        @item.entries.each {|e| _item_row(e) }
      end
    end
    
    def _item_row(that)
      
    end
    
  end
end