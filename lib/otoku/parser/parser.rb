require 'digest/md5'
require 'fileutils'
require File.dirname(__FILE__) + '/parser_cache'
require File.dirname(__FILE__) + '/model_methods'
require File.dirname(__FILE__) + '/hpricot_based'

module OTOCS
  
  class << self
    attr_accessor :cache_driver
  end
  
  # Read an archive from +path+. Will save and/or reuse the object cache as necessary
  def self.read_archive_file(path)
    # Always contains one archive
    data = File.read(path).to_s
    
    @cache_driver ||= OTOCS::BypassCache.new
    @cache_driver.cached(data) do
      arch = self.parse(data)
      arch.path, arch.etag = File.expand_path(path), Digest::MD5.hexdigest(data)
      arch
    end
  end
  
end