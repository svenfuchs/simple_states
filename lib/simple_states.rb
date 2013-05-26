require 'active_support/core_ext/object/try'

module SimpleStates
  class TransitionException < RuntimeError; end

  autoload :Event,  'simple_states/event'
  autoload :States, 'simple_states/states'

  def self.included(base)
    base.extend SimpleStates::ClassMethods
    # Add class level attribute accessors
    added_class_accessors = [ :state_names, :initial_state, :events ]
    base.singleton_class.send :attr_accessor, *added_class_accessors
    base.public_class_method *added_class_accessors
    base.public_class_method *added_class_accessors.map{|att| "#{att}=".to_sym }
    # default states
    base.after_initialize :init_state if base.respond_to?(:after_initialize)
    base.initial_state = :created
    base.events = []
  end

  module ClassMethods

    def new(*)
      super.tap { |object| States.init(object) }
    end

    def allocate
      super.tap { |object| States.init(object) }
    end

    def states(*args)
      if args.empty?
        self.state_names ||= add_states(self.initial_state)
      else
        options = args.last.is_a?(Hash) ? args.pop : {}
        self.initial_state = options[:initial].to_sym if options.key?(:initial)
        add_states(*[self.initial_state].concat(args))
      end
    end

    def add_states(*states)
      self.state_names = (self.state_names || []).concat(states.compact.map(&:to_sym)).uniq
    end

    def event(name, options = {})
      add_states(options[:to], *options[:from])
      self.events += [Event.new(name, options)]
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

  def respond_to?(method, include_private = false)
    method.to_s =~ /(was_|^)(#{self.class.states.join('|')})\?$/ && self.class.state_names.include?($2.to_sym) || super
  end

  def method_missing(method, *args, &block)
    method.to_s =~ /(was_|^)(#{self.class.states.join('|')})\?$/ ? send(:"#{$1}state?", $2, *args) : super
  end
end

