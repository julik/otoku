require File.dirname(__FILE__) + '/helper'
require 'parser'
require 'fileutils'

class ParserTest < Test::Unit::TestCase
  include THelpers
  
  def test_read_archive_file
    Dir.glob(File.dirname(__FILE__) + '/samples/*.xml').each do | xml |
      assert_nothing_raised { OTOCS.read_archive_file(xml) }
    end
  end
  
  def test_should_reuse_object_cache
    with_cache_dir do | tdir |
      assert_nothing_raised("Should allow setting the directory") { OTOCS.cache_dir = tdir }
      assert File.exist?(tdir), "Should have created the temp dir for object cache"
      assert File.directory?(tdir), "Should have created the directory"
      
      Dir.glob(File.dirname(__FILE__) + '/samples/*.xml').each do | xml |
        assert_nothing_raised { OTOCS.read_archive_file(xml) }
      end
      
      assert Dir.glob(tdir + '/**/*.parsedarchive').any?, "Cache files should have been created"
    end
  end
end

class ArchiveTest < Test::Unit::TestCase
  include THelpers
  include TAccel
  
  ARCH = File.dirname(__FILE__) + '/samples/Flame_Archive_Deel215_08Jul15_1036.xml'
  
  
  def test_archive_attributes
    @node = @archive
    
    assert_string_attribute :name, "Flame_Archive_Deel215"
    assert_string_attribute :machine, "he-flame-01 - flame 2008.SP4"
    assert_string_attribute :comment

    assert_attribute :creation, DateTime
    assert_equal 2008, @node.creation.year
    assert_equal 5, @node.creation.month
  end
  
  def test_archive_to_s
    assert_equal "Flame_Archive_Deel215 (6 sets)", @archive.to_s
  end
  
  def test_archive_device
    assert_respond_to @archive, :device
    assert_kind_of OTOCS::Device, @archive.device
    @node = @archive.device
    
    assert_string_attribute :type, 'VTR'
    assert_string_attribute :name, 'Betacam PAL'
    assert_string_attribute :starts_at, '00:01:00:00'
  end
  
  def test_archive_toc
    assert_respond_to @archive, :toc
    assert_kind_of OTOCS::TOC, @archive.toc
    @node = @archive.toc
    assert @node.respond_to?(:entries)
    assert_kind_of Enumerable, @node.entries
  end
end
