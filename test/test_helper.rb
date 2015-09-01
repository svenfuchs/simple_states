require 'bundler/setup'
require 'minitest/autorun'
require 'test_declarative'
require 'mocha/setup'
require 'simple_states'

module Minitest::Assertions
  def assert_nothing_raised(*)
    yield
  end
end

module ClassCreateHelper
  def create_class(&block)
    self.class.send(:remove_const, :Foo) if self.class.const_defined?(:Foo)

    self.class.const_set(:Foo, Class.new).tap do |klass|
      klass.class_eval do
        include SimpleStates
        instance_eval &block if block_given?
        attr_accessor :state
      end
    end
  end
end
