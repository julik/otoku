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
          @inc = !!@input.inc
          
          expanded_items << _item_identifier(@item)
          render :list_info_bare
        elsif @item.clip?
          render :clip_info
        else
          @headers['Cache-Control'] = 'no-store, no-cache, must-revalidate';
          render :list_info
        end
      end
    end
    
    class CloseBlock < R '/close/(.+)'
      def post(id)
        [id, @input.inc].flatten.compact.each {|e| expanded_items.delete(e) }
      end
    end
    
    class OpenBlock < R '/open/(.+)'
      def post(id)
        [id, @input.inc].flatten.compact.each {|e| expanded_items << e }
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
  
  module Helpers
    def expanded_items
      $expanded_items ||= []
      $expanded_items.uniq!
      $expanded_items
    end

    def _item_uri(item)
      args = [@archive.etag, item.uri.split(/\//)].flatten
      R(::Otoku::Controllers::ShowEntry, *args)
    end
    
    def _item_identifier(item)
      [@archive.etag, item.uri.split(/\//)].flatten.join('-')
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
        body { yield }
        end
      end
    end
    
    def archive_info
      div.stuffSelected!( :style => 'display: none') { "You have n objects selected" }

      h1 @archive
      p @archive.device
      p "Last touched on %s" % @archive.creation
      
      _content_of_and_wrapper(@archive, :class => 'liblist')
    end
    
    def list_info
      div.stuffSelected!( :style => 'display: none') { "You have n objects selected" }

      h1 @item
      ul.liblist { _content_of(@item) }
    end
    
    def list_info_bare
      _content_of(@item)
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
    
    def _item_row(that, with_link = true)
      if that.clip?
        # skip for now
        _clip_proxy(that)
      else
        li :class => that.flame_type do
          cls = 'hd'
          cls << ' empty' if that.entries.empty?
          cls << ' open' if expanded_items.include?(_item_identifier(that)) || @inc
          # _item_uri(that)
          a  :id => _item_identifier(that), :class => cls, :href=>_item_uri(that) do
            self << that
            b.disc ' '
          end
          self << if @inc
            expanded_items << _item_identifier(that)
            _content_of_and_wrapper(that)
          elsif expanded_items.include?(_item_identifier(that))
            _content_of_and_wrapper(that)
          end
        end
      end
    end
    
    def _content_of(that)
      clips, folders = that.entries.partition{|a| a.clip? }
      folders.entries.each { |e|  _item_row(e) }
      clips.each {|c| _item_row(c) }
      hr :class => 'clr' 
    end
    
    def _content_of_and_wrapper(that, extra_list_attrs = {})
      ul(extra_list_attrs) { _content_of(that) }
    end
    
    def _clip_proxy(that)
      attrs = {}
      attrs.merge! :id => _item_identifier(that) unless that.subclip?
      begin
        li.Clip(attrs) do
          img :src => R(Proxy, that.image1)
          i.sc ' '
          b [that.name, that.soft_clip? ? ' []' : ''].join
        end
      rescue Markaby::InvalidXhtmlError # COLOR clip with non-unique ID
        attrs.delete :id
        retry
      end
    end
  end
end