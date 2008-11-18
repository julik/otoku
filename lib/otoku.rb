require 'rubygems'
require 'camping'

$:.unshift File.dirname(__FILE__)
require 'otoku/parser/parser'

Camping.goes :Otoku
Markaby::Builder.set(:indent, 2)
Markaby::Builder.set(:output_xml_instruction, false)

module Otoku
  VERSION = "0.0.1"
  
  module DataWrangler
    def get_archive_list
      OTOCS.cache_driver = OTOCS::FileCache.new('/tmp')
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
    
    class ShowEntry < R '/entry/([a-z\d]+)/([a-z\d_]+)', '/entry/([a-z\d]+)/([a-z\d_]+)/(\d+)'
      def get(archive_etag, entry_id, subclip_idx = nil)
        @archive = get_archive(archive_etag)
        @item = @archive[entry_id]
        
        if subclip_idx && subclip_idx.to_i > @item.entries.length
          raise "Overflow"
        elsif subclip_idx 
          @item = @item.entries[subclip_idx.to_i]
        end
        
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
        render :archive_info
      end
    end
    
    class ClipImage < R('/cimage/(.+)')
      def get(path)
      end
    end
  end
  
  module Views
    def layout
      yield and return if @bare
      
      html do
      head do
        title Otoku
      end
      body do
        yield
      end
      end
    end
    
    def archive_info
      h1 @archive
      p @archive.device
      p "Last touched on %s" % @archive.creation
      @archive.entries.each do | bs |
        _item_row(bs, false)
        bs.entries.each do | box |
          _item_row(box)
        end
      end
    end
    
    def list_info
      h1 @item
      cls = @item.flame_type rescue 'archive'
      ul(:class => cls) do
        @item.entries.each {|e| _item_row(e) }
      end
    end
    
    def clip_info
      h1 @item
      if @item.soft_clip?
        h2 "Subclips in the edit"
        list_info
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
      args = [@archive.etag, item.uri.split(/\//)].flatten
      R(ShowEntry, *args)
    end
    
    def _item_row(that, with_link = true)
      li { with_link ? (a that, :href => _item_uri(that)) : that }
    end
    
  end
end