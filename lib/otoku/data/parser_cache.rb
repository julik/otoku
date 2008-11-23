module Otoku
module Data
  DIGEST = Digest::MD5
  class BypassCache
    def cached(data)
      STDERR.puts "No cache - things will be very SLOW"
      yield
    end
  end
  
  class FileCache
    attr_accessor :cache
    
    def initialize(dir = nil)
      self.cache_dir = dir
    end
    
    # Set the directory used to store the preparsed OTOC structures
    def cache_dir=(dir)
      @cache = if dir.nil?
        nil
      else
        exp = File.expand_path(dir)
        FileUtils.mkdir_p(exp)
        exp
      end
    end

    # Get the directory used to store the preparsed OTOC structures
    def cache_dir
      @cache
    end
    
    def cached(content)
      unless @cache
        STDERR.puts "No cache dir set - things will be very SLOW"
        return yield 
      end
      
      digest = DIGEST.hexdigest(content)
      path = digest.scan(/(.{8})/).join('/') + '.parsedarchive'
      cache_f = File.join(@cache, path)
      begin
        Marshal.load(read_content_of(cache_f))
     #rescue ArgumentError, TypeError # Improper parse
     #  File.unlink(cache_f)
     #  retry
      rescue Errno::ENOENT # improper parse
        parsed = yield
        FileUtils.mkdir_p(File.dirname(cache_f))
        mar = Marshal.dump(parsed)
        write_content(cache_f, mar)
        parsed
      end
    end
    
    def write_content(cache_f, bytes)
      File.open(cache_f, 'w') { | to |  to << bytes }
    end
    
    def read_content_of(cache_f)
      File.read(cache_f)
    end
  end
  
  begin
    require 'zlib'
    # Gzip is very efficient with Ruby marshals. We can achieve compression up to 20 times
    class GzipCache < FileCache
      def write_content(cache_f, bytes)
        File.open(cache_f +'.gz', 'w') do | f |
          gz = Zlib::GzipWriter.new(f)
          gz <<  bytes; gz.close
        end
      end
      
      def read_content_of(cache_f)
        File.open(cache_f + '.gz') do |f|
          gz = Zlib::GzipReader.new(f)
          gz.read
        end
      end
    end
    
    silence_warnings { FileCache = GzipCache } # :-)
  rescue LoadError
  end
  
  class MemoCache
    @@parsed ||= {}
    def cached(content)
      digest = Digest::MD5.hexdigest(content)
      @@parsed[digest] ||= yield
      @@parsed[digest]
    end
  end

end
end