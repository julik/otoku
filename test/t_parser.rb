require File.dirname(__FILE__) + '/helper'
require 'fileutils'


class ArchiveTest < Test::Unit::TestCase
  include THelpers
  
  ARCH = File.dirname(__FILE__) + '/samples/TestableArch_08Nov27_1513.xml'
  
  def setup
    [Otoku::Models::Archive, Otoku::Models::Entry].map(&:delete_all)
    @archive = Otoku::HpricotParser.new.parse(File.open(ARCH, 'r'))
    @archive.update_attributes :etag => Digest::MD5.hexdigest(File.read(ARCH))
  end
  
  def test_archive_attributes
    
    @node = @archive
    
    assert_string_attribute :name, "TestableArch"
    assert_string_attribute :comment, "This is a comment"
    assert_string_attribute :appstring, "he-flame-01 - flame 2009.1.SP1"
    assert_attribute :creation, DateTime
    assert_equal 2008, @node.creation.year
    assert_equal 11, @node.creation.month

#    assert_attribute :device, Otoku::Data::Device
  end
  
  def test_archive_to_s
    assert_equal "TestableArch (one set)", @archive.to_s
  end
  
  def test_archive_etag
    assert_equal Digest::MD5.hexdigest(File.read(ARCH)), @archive.etag
  end
  
  def test_archive_device
    assert_respond_to @archive, :device
    
    @node = @archive.device
    assert_string_attribute :type, 'VTR'
    assert_string_attribute :name, 'Betacam PAL'
    assert_string_attribute :starts, '00:01:00:00'
    
    assert_equal "VTR - Betacam PAL - 00:01:00:00", @node.to_s
  end
  
  def test_archive_toc
    assert @archive.respond_to?(:entries)
    assert_kind_of Enumerable, @archive.entries
    assert_equal 1, @archive.entries.length
  end
  
  def test_backup_set_entry
    @node = @archive.entries[0]
    
    assert_not_nil @node
    
    assert_equal @archive, @node.archive

    assert_respond_to @node, :backup_set?
    assert @node.backup_set?
    assert !@node.desktop?
    assert !@node.library?
    assert !@node.reel?
    assert !@node.clip?
    assert !@node.subclip?
    assert_equal "Backup Set -  2008/11/27 15:11:08 (BackupSet) - empty", @node.to_s
  end
  
  def test_library_entry
    @node = @archive.entries[0][0]
    
    assert_not_nil @node
    assert_respond_to @node, :library?

    assert_equal @archive, @node.archive
    assert_equal @archive.entries[0], @node.parent
    
    assert_equal "Tonda_Let_It_Shine", @node.name
    assert @node.library?
    assert !@node.desktop?
    assert !@node.backup_set?
    assert !@node.clip?
    assert !@node.subclip?
    assert_equal "Tonda_Let_It_Shine (Library) - 2 items", @node.to_s
    assert_equal 2, @node.entries.length
  end

  def test_reel_entry
    @node = @archive.entries[0][0][0]
    assert_not_nil @node
    assert_respond_to @node, :reel?
    
    assert_equal "E_temp", @node.name

    assert_equal @archive, @node.archive
    assert_equal @archive.entries[0][0], @node.parent
    
    assert @node.reel?
    assert !@node.desktop?
    assert !@node.library?
    assert !@node.backup_set?
    assert !@node.clip?
    assert !@node.subclip?
    assert_equal "E_temp (Reel) - 12 items", @node.to_s
    assert_equal 12, @node.entries.size
  end
  
  def test_desk_entry
    flunk "Not present in the test arch"
    
    @node = @archive.child_by_id('a8c01bab_48316b7f_000231dd')
    assert_not_nil @node
    assert_respond_to @node, :desktop?
    
    assert @node.desktop?
    assert !@node.clip?
    assert !@node.subclip?
    assert !@node.reel?
    assert !@node.library?
    assert !@node.backup_set?
  end
  
  def test_get_entry_path
    item = @archive[0][0][1]
    assert_not_nil item
    
    assert_equal "0/0/1", item.path
    assert_equal "E_temp_2", item.name
  end
  
  def test_get_entry_by_path
    path = "0/0/1"
    item = @archive.get_by_path(path)
    assert_not_nil item

    assert_equal "0/0/1", item.path
    assert_equal "E_temp_2", item.name
  end
  
  def test_image1_image2_on_entry
    uri = 'a8c01bab_48108fe3_0004ad1e'
    @node = @archive[uri]
    
    assert_not_nil @node
    assert_string_attribute :image1, 'Flame_Archive_Deel215_08Jul15_1036/a8c01bab_48108fe3_0004ad1e_1.jpg'
    assert_string_attribute :image2, 'Flame_Archive_Deel215_08Jul15_1036/a8c01bab_48108fe3_0004ad1e_2.jpg'
    assert_integer_attribute :length, 40
  end
end
