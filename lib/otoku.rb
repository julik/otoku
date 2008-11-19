require 'rubygems'
require 'camping'

$:.unshift File.dirname(__FILE__)
require 'otoku/data/parser_cache'
require 'otoku/data/model_methods'
require 'otoku/data/hpricot_based'
require 'otoku/data/parser'

Camping.goes :Otoku
Markaby::Builder.set(:indent, 2)
Markaby::Builder.set(:output_xml_instruction, false)

module Otoku
  VERSION = "0.0.1"
  
  module DataWrangler
    def get_archive_list
      Otoku::Data.cache_driver = Otoku::Data::FileCache.new('/tmp')
      @archives ||= Dir.glob(File.dirname(__FILE__) + '/../test/samples/*.xml').map do | arch |
        Otoku::Data.read_archive_file(arch)
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
        
        if @input.bare
          @bare = true
          render :list_info_bare
        elsif @item.clip?
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
    
    class Asset < R('/ui/([\w-]+).(css|png|jpg|gif|js)')
      def get(file, ext)
        File.read(File.dirname(__FILE__) + ('/../ui/%s.%s' % [file,ext]))
      end
    end
    
    class Proxy < R('/proxy/(.+)')
      def get(fname)
        @status = 404
        return #TODO
      end
      
      def head(fname)
        @status = 304
        return
      end
        
    end
  end
  
  module Views
    def layout
      if @bare
        yield
      else
        html do
        head do
          title Otoku
          link :rel=>:stylesheet, :href => R(Asset, "otoku", "css")
          script :src => "http://ajax.googleapis.com/ajax/libs/prototype/1.6.0.2/prototype.js"
          script :src => R(Asset, "libview", "js")
        end
        body do
          yield
        end
        end
      end
    end
    
    def archive_info
      h1 @archive
      p @archive.device
      p "Last touched on %s" % @archive.creation
      ul.liblist do
        @archive.entries.each do | bs |
          _item_row(bs, false)
          bs.entries.each do | box |
            _item_row(box)
          end
        end
      end
    end
    
    def list_info
      h1 @item
      ul.liblist do
        list_info_bare
      end
    end
    
    def list_info_bare
      # Show clips last
      folders = @item.entries.select{|a| !a.clip? }
      clips = @item.entries.select{|a| a.clip? }

      folders.entries.each { |e|  _item_row(e) }
      clips.each {|c| _item_row(c) }
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
    
    def _item_identifier(item)
      [@archive.etag, item.uri.split(/\//)].flatten
    end
    
    def _item_row(that, with_link = true)
      if that.clip?
        # skip for now
        _clip_proxy(that)
      else
        li :class => that.flame_type do
          a  :id => _item_identifier(that), :class => 'hd', :href=>_item_uri(that) do
            self << that
            b.disc ' '
          end
        end
      end
    end
    
    def _content_of(that)
      ul { that.entries.each{|e| _item_row(e) }}
    end
    
    def _clip_proxy(that)
      li.clip :id => _item_identifier(that) do
        img :src => R(Proxy, that.image1)
        i.sc ' '
        b [that.name, that.soft_clip? ? ' []' : ''].join
      end
    end
  end
end