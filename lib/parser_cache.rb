module OTOCS
  class BypassCache
    def cached(data)
      yield
    end
  end
  
  class FileCache
    attr_accessor :cache
    
    def initialize(dir = nil)
      self.cache_dir = nil
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
      return yield unless @cache

      digest = Digest::MD5.hexdigest(content)
      path = digest.scan(/(.{2})/).join('/') + '.parsedarchive'
      cache_f = File.join(@cache, path)
      begin
        Marshal.load(File.read(cache_f))
      rescue Errno::ENOENT
        parsed = yield
        FileUtils.mkdir_p(File.dirname(cache_f))
        File.open(cache_f, 'w') { | to |  to << Marshal.dump(parsed) }
        parsed
      end
    end
  end
  
  class MemoCache
    @@parsed ||= {}
    def self.cached(content)
      digest = Digest::MD5.hexdigest(content)
      @@parsed[digest] ||= yield
      @@parsed[digest]
    end
  end
end