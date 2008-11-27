$:.unshift File.dirname(__FILE__) + '/../lib'
require 'otoku'
require 'mosquito'

Otoku.create

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