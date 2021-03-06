require 'rubygems'
require 'camping'
require 'camping/db' 
require 'fileutils'
require 'digest/md5'
require 'ferret'

$:.unshift File.dirname(__FILE__)
require 'otoku/data/parser_cache'
require 'otoku/data/model_methods'
require 'otoku/data/hpricot_based'
require 'otoku/data/date_parser'
require 'otoku/data/manager'
require 'otoku/data/search'
require 'otoku/builder_hack'
require 'otoku/sorting'
require 'otoku/julik_state'
require 'otoku/timecode/timecode'

Camping.goes :Otoku
Markaby::Builder.set(:indent, 2)
Markaby::Builder.set(:output_xml_instruction, false)

module Otoku
  VERSION = "0.0.1"
  DATA_DIR = File.dirname(__FILE__) + '/../test/samples'
  cache = lambda { File.join(DATA_DIR, '/.otoku') }
  class << cache; alias_method :to_str, :call; end
  CACHE_DIR = cache 
  module Janitor
    def service(*a)
      returning(super(*a)) { GC.start }
    end
  end
  
  include JulikState
  include Janitor
  
  module Controllers
    # Show the list of archives in the system
    class Index < R '/'
      def get
        @archives = get_archive_list
        render :welcome
      end
    end

    # Show the list of items in an archive
    class ShowArchive < R '/archive/(.+)'
      def get(archive_etag)
        @archive = get_archive(archive_etag)
        @title = @archive.name
        @item = @archive
        initialize_sorting
        render :archive_info
      end
      
    end
    
    # Show an archive entry, be it a clip a reel or anything else
    class ShowEntry < R '/entry/([a-z\d]+)/([\d\/]+)'
      def get(archive_etag, entry_path)
        @archive = get_archive(archive_etag)
        @item = @archive.get_by_path(entry_path)
        
        initialize_sorting
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
    
    # Register a block as closed
    class CloseBlock < R '/close/(.+)'
      def post(id)
        [id, @input.inc].flatten.compact.each {|e| expanded_items.delete(e) }
      end
    end

    # Register a block as open
    class OpenBlock < R '/open/(.+)'
      def post(id)
        [id, @input.inc].flatten.compact.each {|e| expanded_items << e }
      end
    end

    # Change sorting options and redirect back
    class ChangeSort < R '/change-sorting'
      def post
        @state.sort_field, @state.sort_flip = @input.sort_field, (@input.sort_flip == '1')
        redirect @env['HTTP_REFERER']
      end
    end
    
    # Search for an item
    
    class Search < R '/search/(.+)'
      def get(query)
        @results = searcher.query(query).uniq
        initialize_sorting
        render :search_results
      end
    end
    
    class Asset < R('/ui/([\w-]+).(css|png|jpg|gif|js)')
      def get(file, ext)
        @headers['Content-Type'] = 'text/' + ext;
        File.read(File.dirname(__FILE__) + ('/../ui/%s.%s' % [file,ext]))
      end
    end
    
    # Fetch the image for a clip proxy. Cache indefinitely
    class Proxy < R('/proxy/(.+)')
      # TODO - ensure that the second request never happens
      def get(fname)
        @headers.merge! 'Last-Modified' => 2.days.ago.to_s(:http),
          'Expires' => 365.days.from_now.to_s(:http),
          'Cache-Control' => "public; max-age=#{365.days}",
          'Content-Type' => 'image/jpeg'
        File.read(File.join(DATA_DIR, fname))
      end
      
      def head(fname)
        @headers.merge! 'Last-Modified' => 2.days.ago.to_s(:http),
          'Expires' => 365.days.from_now.to_s(:http),
          'Cache-Control' => "public; max-age=#{365.days}",
          'Content-Type' => 'image/jpeg'
        @status = 304
      end
    end
  end
  
  module Helpers
    # Get the array of expanded items from the session. The array saves
    # which items are open or closed
    def expanded_items
      @state = ($state ||= Camping::H.new)
      
      @state.expanded_items ||= []
      @state.expanded_items.uniq!
      @state.expanded_items
    end
    
    def initialize_sorting
      @sort = Sorting::Decorator.new
      @sort.field = @state.sort_field if @state.sort_field
      @sort.flip =  @state.sort_flip if @state.sort_flip
    end
    
    def get_archive_list
      @manager ||= Otoku::Data::Manager.new(DATA_DIR)
      @manager.map { | h | h }
    end
    
    def searcher
      @manager ||= Otoku::Data::Manager.new(DATA_DIR)
      Otoku::Data::Searcher.new(@manager)
    end
    
    def get_archive(etag)
      the_a = get_archive_list.find{|a| a.etag == etag }
      the_a.read_struct
    end

    def _item_uri(item)
      et = (item.etag rescue @archive.etag)
      args = [et, item.path.split(/\//)].flatten
      R(::Otoku::Controllers::ShowEntry, args.shift, '') + args.join('/')
    end
    
    def _item_identifier(item)
      et = (item.etag rescue @archive.etag)
      [et, item.path.split(/\//)].flatten.join('-')
    end
    
  end
  
  module Views
    def layout
      if @bare
        yield
      else
        capture do # http://blog.evanweaver.com/articles/2006/10/17/make-camping-output-a-doctype-properly/
        xhtml_transitional do
          head do
            title [Otoku, @title].compact.join('::')
            link :rel=>:stylesheet, :href => R(Asset, "otoku", "css")
            link :media=>"handheld, screen and (max-device-width: 480px)", 
              :href=>R(Asset, "otoku-iphone", "css"),:type=>"text/css", :rel=> :stylesheet
            self <<   '<!--[if IE]>
                    <link href="*" rel="stylesheet" type="text/css" media="screen"/>
              <![endif]-->'.gsub(/\*/, R(Asset, 'otoku-ie', 'css'))
            meta :name => :viewport, :content =>"width=320"
            script :src => "http://ajax.googleapis.com/ajax/libs/prototype/1.6.0.2/prototype.js"
            script :src => R(Asset, "libview", "js")
          end
          body { yield }
        end
      end
      end
    end
    
    def archive_info
      div.stuffSelected!( :style => 'display: none') { "You have n objects selected" }
      h1 @archive
      p "%s, last opened on %s" % [@archive.device, @archive.creation.strftime("%d/%m/%y")]
      _viewing_help
      _sorting_options
      _content_of_and_wrapper(@archive, :class => 'liblist')
    end
    
    def _sorting_options
      form.sortForm :action => R(ChangeSort), :method=>:post do
        self << "Display entries sorted by "
        select :name => :sort_field do
          Sorting::CHOICES.each_pair do | k, v|
            opts = {:value => v}
            opts[:selected] = :selected if @state.sort_field == v.to_s
            option k, opts
          end
        end
        label do
          self << 'in reverse'
          opts = {:name => :sort_flip, :type => :checkbox, :value => 1}
          input(@state.sort_flip ? opts.merge(:checked => 1) : opts)
        end
        input :type => :submit, :value => 'Sort!'
      end
    end
    
    def list_info
      div.stuffSelected!( :style => 'display: none') { "You have n objects selected" }
      _breadcrumb
      h1 @item.name
      _sorting_options
      _viewing_help
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
          
          a  :id => _item_identifier(that), :class => cls, :href=>_item_uri(that) do
            b.disc ' '
            self << that
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
      @sort.apply(folders.entries).each { |e|  _item_row(e) }
      @sort.apply(clips).each {|c| _item_row(c) }
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
          i.le(Timecode.new(that.length))
          b [that.name, that.soft_clip? ? ' []' : ''].join
        end
      rescue Markaby::InvalidXhtmlError # COLOR clip with non-unique ID
        attrs.delete :id
        retry
      end
    end
    
    def _breadcrumb
      ul.crumb do
        li { a Otoku, :href => R(Index) }
        li { a @archive.name, :class => :archive, :href => R(ShowArchive, @archive.etag) }
        @item.parent_chain.each do | parent |
          li { a parent.name, :href => _item_uri(parent), :class => parent.flame_type }
        end
      end
    end
    
    def search_results
      h1 "Here's what we traced"
      ul.liblist do
        @results.each do | res |
          begin
            _item_row(res)
          rescue Markaby::InvalidXhtmlError
          end
        end
      end
    end
    
    def _viewing_help
      div.help do
        p "Double click expands/collapses entries, Alt+double click expands and collapses including chldren.
        Shift + doubleclick focuses on an entry"
      end
    end
  end
  
  def self.create
    #FileUtils.rm_rf CACHE_DIR
    FileUtils.mkdir_p CACHE_DIR
    STDERR.puts "** Making cache directory in #{CACHE_DIR}"
    
    [self::Models, JulikState].each{|e| e.create_schema }
  end
end