require 'active_support/core_ext/module/delegation'
require 'hashr'

module SimpleStates
  class Event
    attr_accessor :name, :options

    def initialize(name, options = {})
      @name    = name
      @options = Hashr.new(options) do
        def except
          self[:except]
        end
      end
    end

    def saving
      @saving = true
      yield.tap { @saving = false }
    end

    def call(object, *args)
      return if skip?(object, args)

      raise_invalid_transition(object) unless can_transition?(object)
      run_callbacks(object, :before, args)
      set_state(object)

      yield.tap do
        run_callbacks(object, :after, args)
        raise_unknown_target_state(object) unless known_target_state?(object)
        object.save! if @saving
      end
    end

    def merge(other, append = true)
      other.options.each do |key, value|
        options[key] = [options[key]].send(append ? :push : :unshift, value).compact.flatten
      end
    end

    protected

      def skip?(object, args)
        result = false
        result ||= !send_methods(object, options.if, args) if options.if?
        result ||= send_methods(object, options.unless, args) if options.unless?
        result
      end

      def can_transition?(object)
        !options.from || object.state && Array(options.from).include?(object.state.to_sym)
      end

      def run_callbacks(object, type, args)
        object.save! if @saving
        send_methods(object, options.send(type), args)
      end

      def set_state(object)
        state = target_state
        object.past_states << object.state if object.state
        object.state = state.to_sym
        object.send(:"#{state}_at=", now) if object.respond_to?(:"#{state}_at=") && object.respond_to?(:"#{state}_at") && object.send(:"#{state}_at").nil?
      end

      def target_state
        options.to || :"#{name}ed"
      end

      def send_methods(object, methods, args)
        Array(methods).inject(false) { |result, method| result | send_method(object, method, args) } if methods
      end

      def send_method(object, method, args)
        arity = self.arity(object, method)
        args = [name].concat(args)
        object.send method, *args.slice(0, arity < 0 ? args.size : arity)
      end

      def arity(object, method)
        object.class.instance_method(method).arity rescue 0
      end

      def now
        Time.respond_to?(:zone) && Time.zone ? Time.zone.now : Time.now.utc
      end

      def known_target_state?(object)
        object.state && object.class.states.include?(object.state.to_sym)
      end

      def raise_invalid_transition(object)
        raise TransitionException, "#{object.inspect} can not receive event #{name.inspect} while in state #{object.state.inspect}."
      end

      def raise_unknown_target_state(object)
        raise TransitionException, "unknown target state #{object.state.inspect} for #{object.inspect} for event #{name.inspect}. known states are #{object.class.states.inspect}"
      end
  end
end
