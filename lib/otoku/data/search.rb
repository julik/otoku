class Otoku::Data::Search
  FERRET_OPTIONS = {
     :default_field=>'*',
     :key=>'identifier',
     :auto_flush => true,
  }
  
  FIELD_OPTS = {:store => :yes, :index => :yes}
  
  def initialize(manager)
    @manager = manager
    
    if (!File.exist?(idx_path))
      FileUtils.mkdir_p(idx_path)
      @ferret_index = Ferret::Index::Index.new(FERRET_OPTIONS.merge(:path => idx_path))    
      @ferret_index.field_infos.add_field(:identifier, FIELD_OPTS)
      @ferret_index.field_infos.add_field(:flame_type, FIELD_OPTS)
      @ferret_index.field_infos.add_field(:text, FIELD_OPTS)
      @ferret_index.field_infos.add_field(:creation, FIELD_OPTS)
      @ferret_index.field_infos.add_field(:archived, FIELD_OPTS)
    else
      @ferret_index = Ferret::Index::Index.new(FERRET_OPTIONS.merge(:path => idx_path))    
    end
  end
  
  class Result
    include Otoku::Data::ModelMethods::EntryMethods
    include Otoku::Data::ModelMethods::EntryKey
    
    # Only these attrs will be carried over to the handle - it has to be economical
    ATTRS = [:creation, :name, :classid, :length, :width, :depth, :image1, :path, :flame_type]
    ATTRS.each {|a| attr_accessor a }
    
    # Entries are accessed separetely
    attr_accessor :entries
    attr_reader :etag

    def initialize(real_entry, etag)
      @entries = []
      @etag = etag
      ATTRS.each{ |a| self.send("#{a}=", real_entry.send(a)) }
    end
    
    def to_s
      "%s (%s)" % [name, flame_type]
    end
    
  end
  
  # Convert etag/path combos to handles to real search results
  # # Scan the Ferret index for entries resembling our one
  # Get it's identifier and archive etag, sort identifiers
  # For each archive etag
  # Split the found identifiers on path boundaries. they are sorted so will walk OK
  # Add the first level
  # ..and second (remember keys are sorted)
  # and down and down
  # close the archive
  # GC
  def identifiers_to_search_results(found_identifiers)
    handles = []
    
    # Sort the list so that we walk the archives sequentially
    found_identifiers.sort.each do | identifier |
      etag, *path_segments = identifier.split("/")

      # load the archive currently being used, identifiers are sorted so we will not run out
      load_archive_under(etag)
      ints = path_segments.map{|e| e.to_i}
      item = @archive.get_by_path(ints)
      
      handle = Result.new(item, @archive.etag)
     	handle.entries = item.entries
     	
     	handles << handle
    end
    handles = handles.partition{|e| !e.clip? }.flatten
  end
  
  def add_entry(entry)
    doc = record_to_ferret_document(entry)
    @ferret_index << doc
  end
  
  def flush
    @ferret_index.flush
  end
  
  def query(query, options = {})
    found_ids = []
    query = "text:(#{query})"
        
    @ferret_index.search_each(query) do | doc_offset, score|
       found_ids << @ferret_index[doc_offset][:identifier]
    end
    
    identifiers_to_search_results(found_ids)
  end
  
  private
  
  def tokenize(anything)
  	# Basic cleanuo
  	words = anything.to_s.split(/(\s|\-|\_|\(|\)|\{|\}|\.|\,|\:|\;)/).map do | word |
  	  word.gsub(/([^\w])/, '').strip
    end
  
    # Remove empty pieces
    words.reject! { |w| w.empty? }
  
    # Tokenize CamelCase and 
    words += words.map do | str |
      pieces = str.gsub(/([A-Z]+|[A-Z][a-z])/) {|x| ' ' + x }.gsub(/[A-Z][a-z]+/) {|x| ' ' + x }.split
      pieces + [str.gsub(/\s/, '')]
    end.flatten
  
    # Reject words shorter than 3
    words.reject! do | word |
      word.empty? || word.length < 3
    end
  
    (words + words.map{|w| w.downcase})
  end
  
  def record_to_ferret_document(entry)
    doc = Ferret::Document.new
    doc[:identifier] = entry.archive.etag + '/' + entry.path
    doc[:text] = tokenize(entry.name).uniq.join(' ')
    doc[:flame_type] = entry.flame_type
    doc[:creation] = entry.creation
    doc[:archived] = entry.archive.creation
    doc
  end
  
  def load_archive_under(etag)
    if !@archive || @archive.etag != etag
    	@archive = nil
    	GC.start
      @archive = @manager.read_archive(etag)
    end
  end
  
  def idx_path
    @manager.data_dir + '/_idx'
  end
  

end