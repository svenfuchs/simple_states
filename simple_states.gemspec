# encoding: utf-8

$:.unshift File.expand_path('../lib', __FILE__)
require 'simple_states/version'

Gem::Specification.new do |s|
  s.name         = "simple_states"
  s.version      = SimpleStates::VERSION
  s.authors      = ["Sven Fuchs"]
  s.email        = "svenfuchs@artweb-design.de"
  s.homepage     = "https://github.com/svenfuchs/simple_states"
  s.licenses     = ['MIT']
  s.summary      = "[summary]"
  s.description  = "[description]"

  s.files        = Dir.glob("{lib/**/*,[A-Z]*}")
  s.platform     = Gem::Platform::RUBY
  s.require_path = 'lib'
  s.rubyforge_project = '[none]'

  s.add_dependency 'activesupport'
  s.add_dependency 'hashr', '~> 0.0.10'

  s.add_development_dependency 'rake', '~> 0.9.2'
  s.add_development_dependency 'test_declarative'
  s.add_development_dependency 'mocha'
end
