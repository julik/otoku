require 'digest/md5'
require 'fileutils'

module Otoku
  module Data
    class << self
      attr_accessor :cache_driver
    end
  
    # Read an archive from +path+. Will save and/or reuse the object cache as necessary
    def self.read_archive_file(path)
      # Always contains one archive
      data = File.read(path).to_s
    
      @cache_driver ||= Otoku::Data::BypassCache.new
      @cache_driver.cached(data) do
        arch = self.parse(data)
        arch.path, arch.etag = File.expand_path(path), Digest::MD5.hexdigest(data)
        arch
      end
    end
  end
end