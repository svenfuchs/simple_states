require 'bundler/setup'
require 'test/unit'
require 'test_declarative'
require 'mocha/setup'

begin
  require 'ruby-debug'
rescue LoadError => le
  puts "Could not not load ruby-debug, moving on..."
end

require 'simple_states'

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
