require 'bundler/setup'
require 'test/unit'
require 'test_declarative'
require 'ruby-debug'
require 'simple_states'

module ClassCreateHelper
  def create_class(&block)
    klass = Class.new do
      include SimpleStates
      instance_eval &block

      attr_accessor :state

      def initialize
        @state = :created
      end
    end

    self.class.send(:remove_const, :Foo) if self.class.const_defined?(:Foo)
    self.class.const_set :Foo, klass
  end
end
