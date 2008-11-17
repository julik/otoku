require File.dirname(__FILE__) + '/helper'
require 'parser'
require 'fileutils'

class ParserTest < Test::Unit::TestCase
  def test_read_archive_file
    Dir.glob(File.dirname(__FILE__) + '/samples/*.xml').each do | xml |
      assert_nothing_raised { OTOCS.read_archive_file(xml) }
    end
  end
  
  def test_should_reuse_object_cache
    tdir = File.dirname(__FILE__) + '/temp'
    begin
      assert_nothing_raised("Should allow setting the directory") { OTOCS.cache_dir = tdir }
      assert File.exist?(tdir), "Should have created the temp dir for object cache"
      assert File.directory?(tdir), "Should have created the directory"
      
      Dir.glob(File.dirname(__FILE__) + '/samples/*.xml').each do | xml |
        assert_nothing_raised { OTOCS.read_archive_file(xml) }
      end
      
      assert Dir.glob(tdir + '/**/*.parsedarchive').any?, "Cache files should have been created"
    ensure
      OTOCS.cache_dir = nil
      FileUtils.rm_rf tdir
    end
  end
end