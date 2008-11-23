require File.dirname(__FILE__) + '/helper'
require 'fileutils'

class ParserCacheTest < Test::Unit::TestCase
  include THelpers
  
  def test_read_archive_file
    Dir.glob(File.dirname(__FILE__) + '/samples/*.xml').each do | xml |
      assert_nothing_raised { Otoku::Data.read_archive_file(xml) }
    end
  end
  
  def test_should_reuse_object_cache
    with_cache_dir do | tdir |
      assert_nothing_raised("Should allow setting the directory") { Otoku::Data.cache_driver.cache_dir = tdir }
      assert File.exist?(tdir), "Should have created the temp dir for object cache"
      assert File.directory?(tdir), "Should have created the directory"
      
      Dir.glob(File.dirname(__FILE__) + '/samples/*.xml').each do | xml |
        assert_nothing_raised { Otoku::Data.read_archive_file(xml) }
      end
      
      assert Dir.glob(tdir + '/**/*.parsedarchive.gz').any?, "Cache files should have been created"
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
    assert_string_attribute :comment, ""
    assert_string_attribute :appstring, "he-flame-01 - flame 2008.SP4"
    assert_attribute :device, Otoku::Data::Device
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
    assert_kind_of Otoku::Data::Device, @archive.device
    
    @node = @archive.device
    assert_string_attribute :type, 'VTR'
    assert_string_attribute :name, 'Betacam PAL'
    assert_string_attribute :starts, '00:01:00:00'
    
    assert_equal "VTR - Betacam PAL - 00:01:00:00", @node.to_s
  end
  
  def test_archive_device_joins_attribs
    ef = File.dirname(__FILE__) + '/samples/Bavaria_HighRes-Flame2008_08Oct28_1107.xml'
    @archive = Otoku::Data.read_archive_file(ef)
    assert_equal "File - /usr/data/Flame_Backup_Disk/BavariaHighRes", @archive.device.to_s
  end
  
  def test_archive_toc
    @node = @archive
    assert @node.respond_to?(:entries)
    assert_kind_of Enumerable, @node.entries
  end
  
  def test_backup_set_entry
    @node = @archive.entries[0]
    assert_not_nil @node
    assert_kind_of Otoku::Data::Entry, @node
    assert_respond_to @node, :backup_set?
    
    assert_equal @archive, @node.archive
    assert_equal @archive, @node.parent

    assert @node.backup_set?
    assert !@node.desktop?
    assert !@node.library?
    assert !@node.reel?
    assert !@node.clip?
    assert !@node.subclip?
    assert_equal "Backup Set -  2008/05/19 13:48:44 (BackupSet) - one item", @node.to_s
  end
  
  def test_library_entry
    @node = @archive.entries[0][0]
    assert_not_nil @node
    assert_kind_of Otoku::Data::Entry, @node
    assert_respond_to @node, :library?

    assert_equal @archive, @node.archive
    assert_equal @archive.entries[0], @node.parent
    
    assert_equal "Vodafone_Reedit", @node.name
    assert @node.library?
    assert !@node.desktop?
    assert !@node.backup_set?
    assert !@node.clip?
    assert !@node.subclip?
    assert_equal "Vodafone_Reedit (Library) - 13 items", @node.to_s
    assert_equal 13, @node.entries.length
  end

  def test_reel_entry
    @node = @archive.entries[0][0][0]
    assert_not_nil @node
    assert_kind_of Otoku::Data::Entry, @node
    assert_respond_to @node, :reel?
    
    assert_equal "Artwork_24_04_08", @node.name
    assert_equal @archive, @node.archive
    assert_equal @archive.entries[0][0], @node.parent
    
    assert @node.reel?
    assert !@node.desktop?
    assert !@node.library?
    assert !@node.backup_set?
    assert !@node.clip?
    assert !@node.subclip?
    assert_equal "Artwork_24_04_08 (Reel) - empty", @node.to_s
    assert @node.entries.empty?
  end
  
  def test_desk_entry
    @node = @archive.child_by_id('a8c01bab_48316b7f_000231dd')
    assert_not_nil @node
    assert_kind_of Otoku::Data::Entry, @node
    assert_respond_to @node, :desktop?
    
    assert @node.desktop?
    assert !@node.clip?
    assert !@node.subclip?
    assert !@node.reel?
    assert !@node.library?
    assert !@node.backup_set?
  end
  
  def test_fetch_key
    key = 'a8c01bab_4831691c_00086eed'
    item = @archive.child_by_id(key)
    assert_not_nil item
    assert_kind_of Otoku::Data::Entry, item
    assert item.backup_set?
    assert_equal item.id, 'a8c01bab_4831691c_00086eed'
  end
  
  def test_fetch_with_uri
    uri = "a8c01bab_4831691c_00086eed/a8c01bab_4831691c_00086ef4/a8c01bab_4831691c_00086eff/a8c01bab_48108fe3_0004ad1e/a8c012ab_487c60d9_0004469e"
    total_uri = @archive.etag + '/' + uri
    item = @archive.fetch_uri(uri)
    assert_not_nil item
    assert_kind_of Otoku::Data::Entry, item
    assert item.subclip?
    assert_equal "boomInzet", item.name
    assert_equal "a8c012ab_487c60d9_0004469e", item.id
    
    assert_not_nil item.parent
    assert_equal 'a8c01bab_48108fe3_0004ad1e', item.parent.id
  end
  
  def test_fetch_with_id
    uri = "a8c012ab_487c60d9_0004469e"
    item = @archive.child_by_id(uri)
    assert_not_nil item
    assert_kind_of Otoku::Data::Entry, item
    assert_equal uri, item.id
    assert_equal "boomInzet", item.name
    assert item.subclip?
  end
  
  def test_get_entry_path
    uri = "a8c012ab_487c60d9_0004469e"
    item = @archive.child_by_id(uri)
    assert_not_nil item
    assert_kind_of Otoku::Data::Entry, item
    
    assert_equal "0/0/1/0/0", item.path
  end
  
  def test_get_entry_by_path
    path = "0/0/1/0/0"
    item = @archive.get_by_path(path)
    assert_not_nil item

    assert_kind_of Otoku::Data::Entry, item
    assert_equal "boomInzet", item.name
    assert_equal path, item.path
  end
  
  def test_image1_image2_on_entry
    uri = 'a8c01bab_48108fe3_0004ad1e'
    @node = @archive[uri]
    
    assert_not_nil @node
    assert_kind_of Otoku::Data::Entry, @node
    assert_string_attribute :image1, 'Flame_Archive_Deel215_08Jul15_1036/a8c01bab_48108fe3_0004ad1e_1.jpg'
    assert_string_attribute :image2, 'Flame_Archive_Deel215_08Jul15_1036/a8c01bab_48108fe3_0004ad1e_2.jpg'
    assert_integer_attribute :length, 40
  end
end
