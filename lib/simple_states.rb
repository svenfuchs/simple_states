require 'active_support/core_ext/object/try'

module SimpleStates
  class TransitionException < RuntimeError; end

  autoload :Event,  'simple_states/event'
  autoload :States, 'simple_states/states'

  class << self
    def included(base)
      base.extend(SimpleStates::ClassMethods)
      define_accessors(base, :state_names, :state_options, :initial_state, :events)
      set_defaults(base)
    end

    def define_accessors(base, *names)
      base.singleton_class.send(:attr_accessor, *names)
      base.public_class_method(*names + names.map { |name| "#{name}=".to_sym })
    end

    def set_defaults(base)
      base.after_initialize(:init_state) if base.respond_to?(:after_initialize)
      base.initial_state = :created
      base.state_names = []
      base.state_options = {}
      base.events = []
    end
  end

  module ClassMethods
    def new(*)
      super.tap { |object| States.init(object) }
    end

    def allocate
      super.tap { |object| States.init(object) }
    end

    def states(*args)
      options = args.last.is_a?(Hash) ? args.pop : {}
      self.initial_state = options.delete(:initial).to_sym if options.key?(:initial)
      self.state_options = options
      add_states(*[self.initial_state].concat(args))
    end

    def add_states(*names)
      self.state_names = self.state_names.concat(names.compact.map(&:to_sym)).uniq
    end

    def event(name, options = {})
      add_states(options[:to], *options[:from])
      self.events += [Event.new(name, options)]
    end

    def states_module
      const_defined?(*args) ? self::StatesProxy : const_set(:StatesProxy, Module.new)
    end
  end

  attr_reader :past_states

  def init_state
    self.state = self.class.initial_state if state.nil?
  end

  def past_states
    @past_states ||= []
  end

  def state?(state, include_past = false)
    include_past ? was_state?(state) : self.state.try(:to_sym) == state.to_sym
  end

  def was_state?(state)
    past_states.concat([self.state.try(:to_sym)]).compact.include?(state.to_sym)
  end
end
