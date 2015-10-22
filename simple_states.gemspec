# encoding: utf-8

$:.unshift File.expand_path('../lib', __FILE__)
require 'simple_states/version'

Gem::Specification.new do |s|
  s.name         = "simple_states"
  s.version      = SimpleStates::VERSION
  s.authors      = ["Sven Fuchs"]
  s.email        = "me@svenfuchs.com"
  s.homepage     = "https://github.com/svenfuchs/simple_states"
  s.licenses     = ['MIT']
  s.summary      = "[summary]"
  s.description  = "[description]"

  s.files        = Dir.glob("{lib/**/*,[A-Z]*}")
  s.platform     = Gem::Platform::RUBY
  s.require_path = 'lib'
  s.rubyforge_project = '[none]'
end
