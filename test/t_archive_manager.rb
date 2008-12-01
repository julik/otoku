require File.dirname(__FILE__) + '/helper'
require 'flexmock'
require 'flexmock/test_unit'

class TestArchiveManager < Test::Unit::TestCase
  def test_creation
    assert defined?(Otoku::Data::Manager)
    assert_respond_to Otoku::Data::Manager, :new
    assert_raise(ArgumentError, "should require an argument") { Otoku::Data::Manager.new }
  end
  
  def test_instantiation_should_glob_the_dir_given
    flexmock(Dir).should_receive(:glob).with('/some/dir/*.xml').and_return([])
    flexmock(FileUtils).should_receive(:mkdir_p).with('/some/dir/.otoku').and_return(true)
    
    assert_nothing_raised { @manager = Otoku::Data::Manager.new('/some/dir') }
    
    assert_equal '/some/dir/.otoku', @manager.data_dir
    assert_respond_to @manager, :empty?
    assert @manager.empty?
    assert_equal 0, @manager.length
  end

  def test_instantiation_should_glob_the_dir_given_and_make_handles
    flexmock(Dir).should_receive(:glob).with('/some/dir/*.xml').and_return(
      %w(  /some/dir/archive1_08Jul10_1209.xml /some/dir/archive2_08Jul12_1210.xml )
    )
    assert_nothing_raised { @manager = Otoku::Data::Manager.new('/some/dir') }
    assert_respond_to @manager, :empty?
    assert !@manager.empty?
    assert_equal 2, @manager.length
    
    handle = @manager.handles[0]
    
    assert_respond_to handle, :name
    assert_equal "archive1", handle.name
    assert_equal DateTime.civil(2008, 7, 10, 12, 9), handle.creation
    assert_equal "archive1_08Jul10_1209.xml", handle.filename
  end
  
  def test_creation_should_glob_the_dir_and_pick_the_latest_file_version
    flexmock(Dir).should_receive(:glob).with('/some/dir/*.xml').and_return(
      %w(  /some/dir/archive1_08Jul15_1209.xml /some/dir/archive1_08Dec15_1210.xml )
    )
    
    assert_nothing_raised { @manager = Otoku::Data::Manager.new('/some/dir') }
    assert_respond_to @manager, :empty?
    assert !@manager.empty?
    
    assert_equal 1, @manager.length, "There should be only one handle available"
    assert_equal 'archive1_08Dec15_1210.xml', @manager.handles[0].filename,
      "The latest file should have been grabbed"
  end
end


class ArchiveHandleTest < Test::Unit::TestCase
  def test_instantiation
    path = '/some/dir/archive1_08Jul15_1209.xml'
    mgr = flexmock :archives_dir => '/other/dir'
    assert_nothing_raised { @handle = Otoku::Data::ArchiveHandle.new(path, mgr) }
    
    assert_respond_to @handle, :name
    assert_equal "archive1", @handle.name
    assert_equal DateTime.civil(2008, 7, 15, 12, 9), @handle.creation
    assert_equal "archive1_08Jul15_1209.xml", @handle.filename
    assert_equal "/other/dir/archive1_08Jul15_1209.xml", @handle.full_path
    assert_equal "/other/dir/archive1_08Jul15_1209.xml", @handle.xml_path
  end
  
  def test_later_entries_sort_last
    paths = %w(
      /some/dir/archive1_07Jul15_1209.xml
      /some/dir/archive1_08Jul15_1209.xml
      /some/dir/archive1_07Jul14_1209.xml
    )
    mgr = flexmock :archives_dir => '/other/dir'
    entries = paths.map{|p| Otoku::Data::ArchiveHandle.new(p, mgr)}
    assert_nothing_raised { entries.sort! }
    assert_equal "archive1_08Jul15_1209.xml", entries[-1].filename
    
  end
end