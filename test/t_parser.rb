require File.dirname(__FILE__) + '/helper'
require 'fileutils'

# class ParserTest < Test::Unit::TestCase
#   include THelpers
#   
#   def test_read_archive_file
#     Dir.glob(File.dirname(__FILE__) + '/samples/*.xml').each do | xml |
#       assert_nothing_raised { OTOCS.read_archive_file(xml) }
#     end
#   end
#   
#   def test_should_reuse_object_cache
#     with_cache_dir do | tdir |
#       assert_nothing_raised("Should allow setting the directory") { OTOCS.cache_driver.cache_dir = tdir }
#       assert File.exist?(tdir), "Should have created the temp dir for object cache"
#       assert File.directory?(tdir), "Should have created the directory"
#       
#       Dir.glob(File.dirname(__FILE__) + '/samples/*.xml').each do | xml |
#         assert_nothing_raised { OTOCS.read_archive_file(xml) }
#       end
#       
#       assert Dir.glob(tdir + '/**/*.parsedarchive').any?, "Cache files should have been created"
#     end
#   end
# end

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
  
  def test_archive_etag
    assert_equal Digest::MD5.hexdigest(File.read(ARCH)), @archive.etag
  end
  
  def test_archive_id_is_etag
    assert_equal @archive.etag, @archive.id
  end
  
  def test_archive_device
    assert_respond_to @archive, :device
    assert_kind_of OTOCS::Device, @archive.device
    @node = @archive.device
    assert_string_attribute :type, 'VTR'
    assert_string_attribute :name, 'Betacam PAL'
    assert_string_attribute :starts, '00:01:00:00'
    
    assert_equal "VTR - Betacam PAL - 00:01:00:00", @node.to_s
  end
  
  def test_archive_toc
    @node = @archive
    assert @node.respond_to?(:entries)
    assert_kind_of Enumerable, @node.entries
  end
  
  def test_backup_set_entry
    @node = @archive.entries[0]
    assert_not_nil @node
    assert_kind_of OTOCS::Entry, @node
    assert_respond_to @node, :backup_set?
    
    assert @node.backup_set?
    assert !@node.library?
    assert !@node.reel?
    assert !@node.clip?
    assert !@node.subclip?
    assert_equal "Backup Set -  2008/05/19 13:48:44 (Backup Set) - 1 items", @node.to_s
  end
  
  def test_fetch_key
    item = @archive['a8c01bab_4831691c_00086eed']
    assert_not_nil item
    assert_kind_of OTOCS::Entry, item
    assert item.backup_set?
  end
  
  def test_fetch_with_uri
    uri = "a8c01bab_4831691c_00086eed/a8c01bab_4831691c_00086ef4/a8c01bab_4831691c_00086eff/a8c01bab_48108fe3_0004ad1e/a8c012ab_487c60d9_0004469e"
    total_uri = @archive.etag + '/' + uri
    item = @archive.fetch_uri(uri)
    assert_not_nil item
    assert_kind_of OTOCS::Entry, item
    assert item.subclip?
    assert_equal "boomInzet", item.name
    assert_equal "a8c012ab_487c60d9_0004469e", item.id
    
    assert_not_nil item.parent
    assert_equal 'a8c01bab_48108fe3_0004ad1e', item.parent.id
  end
  
  def test_fetch_with_id
    uri = "a8c012ab_487c60d9_0004469e"
    item = @archive[uri]
    assert_not_nil item
    assert_kind_of OTOCS::Entry, item
    assert_equal uri, item.id
    assert_equal "boomInzet", item.name
    assert item.subclip?
  end
end
