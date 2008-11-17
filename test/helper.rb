require 'test/unit'
$:.unshift File.dirname(__FILE__) + '/../lib'
require 'parser'


module THelpers
  def with_cache_dir(dir = File.dirname(__FILE__) + '/temp')
    old_td = OTOCS.cache_dir
    begin
      
      yield(dir)
    ensure
      OTOCS.cache_dir = old_td
      FileUtils.rm_rf dir
    end
  end
  
  def assert_string_attribute(attr, value = nil, message = nil)
    assert_attribute(attr, String, value, message)
  end

  def assert_integer_attribute(attr, value = nil, message = nil)
    assert_attribute(attr, Integer, value, message)
  end
  
  def assert_attribute(attr, klass, value = nil, message =  nil)
    assert_not_nil @node, "@node should be set"
    
    message ||= "#{attr} should be a #{klass} attribute on #{@node.class}"
    assert_respond_to @node, attr, message + " but it does not respond"
    assert_kind_of klass, @node.send(attr), message
    
    assert_equal value, @node.send(attr), ":#{attr} should be equal to #{value}" if value
  end
  
end

module TAccel
  TEST_CACHE_DIR = File.join File.dirname(__FILE__), "test-parser-cache-#{Time.now.to_i}"
  Dir.glob(File.dirname(__FILE__) + '/test-parser-cache-*').each do | old_cache |
    FileUtils.rm_rf(old_cache)
  end
  
  def setup
    super
    OTOCS.cache_dir = TEST_CACHE_DIR
    @archive = OTOCS.read_archive_file(self.class.const_get(:ARCH))
  end
  
  def teardown
    OTOCS.cache_dir = nil
    super
  end
end