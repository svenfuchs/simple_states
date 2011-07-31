require 'active_support/concern'
require 'active_support/core_ext/class/inheritable_attributes'
require 'active_support/core_ext/kernel/singleton_class'

module SimpleStates
  class TransitionException < RuntimeError; end

  autoload :Event, 'simple_states/event'

  extend ActiveSupport::Concern

  class << self
    def install(object)
      target = object.singleton_class
      object.class.events.each { |event| define_event(target, event) }
      object.class.states.each { |state| define_predicates(target, state) }
    end

    def define_event(target, event)
      target.send(:define_method, event.name) do |*args|
        event.call(self, *args) do
          super(*args) if self.class.method_defined?(event.name)
        end
      end
    end

    def define_predicates(target, _state)
      target.send(:define_method, :"#{_state}?") do |include_past = false|
        include_past ? send(:"was_#{_state}?") : state == _state
      end

      target.send(:define_method, :"was_#{_state}?") do
        past_states.concat([state]).include?(_state)
      end
    end
  end

  included do
    class_inheritable_accessor :state_names, :events
    self.state_names, self.events = [], []
  end

  module ClassMethods
    def new
      super.tap { |object| SimpleStates.install(object) }
    end

    def states(*args)
      args.empty? ? state_names : self.state_names = args
    end

    def event(name, options = {})
      self.states << options[:from] if options[:from]
      self.states << options[:to]   if options[:to]
      self.events << Event.new(name, options)
    end
  end

  attr_reader :past_states

  def past_states
    @past_states ||= []
  end
end
