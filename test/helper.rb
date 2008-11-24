$:.unshift File.dirname(__FILE__) + '/../lib'
require 'otoku'
require 'mosquito'


module THelpers
  def with_cache_dir(dir = File.dirname(__FILE__) + '/temp')
    cache_d = Otoku::Data::FileCache.new(dir)
    yield(cache_d)
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
    @archive = with_cache_dir(TEST_CACHE_DIR) do | driver |
      f = self.class.const_get(:ARCH)
      driver.cached(f) { Otoku::Data.parse(File.open(f, 'r')) }
    end
  end
end