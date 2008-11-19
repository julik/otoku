$:.reject! { |e| e.include? 'TextMate' }

require 'rubygems'
require 'hoe'
require File.dirname(__FILE__) + '/lib/otoku'

$KCODE = 'u'

class KolkHoe < Hoe
  def define_tasks
    extra_deps.reject! {|e| e[0] == 'hoe' }
    super
  end
end

# Disable spurious warnings when running tests, ActiveMagic cannot stand -w
Hoe::RUBY_FLAGS.replace ENV['RUBY_FLAGS'] || "-I#{%w(lib test).join(File::PATH_SEPARATOR)}" + 
  (Hoe::RUBY_DEBUG ? " #{RUBY_DEBUG}" : '')

KolkHoe.new('Otoku', Otoku::VERSION) do |p|
  p.name = "otoku"
  p.author = "Julik Tarkhanov"
  p.description = "A simple Flame/Smoke archive browser"
  p.email = 'me@julik.nl'
  p.summary = "Useful for the otaku lost in his archive tapes"
  p.url = "http://github.com/julik/otoku"
  p.rdoc_pattern = /lib/
  p.test_globs = 'test/t_*.rb'
  p.extra_deps = ['camping', 'hpricot', ['ruby-openid', '>=2.1.0']]
end