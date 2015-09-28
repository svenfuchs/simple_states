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

    def call(object, *args)
      return false if skip?(object, args) || !set_state?(object, args)

      raise_invalid_transition(object) unless can_transition?(object)
      run_callbacks(object, :before, args)
      set_state(object, args)

      yield.tap do
        raise_unknown_target_state(object) unless known_target_state?(object)
        run_callbacks(object, :after, args)
        object.save! if save?
      end
    end

    def reset(object)
      set_timestamp(object, nil)
    end

    protected

      def save?
        options[:save]
      end

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
        object.save! if save?
        send_methods(object, options.send(type), args)
      end

      def set_state(object, args)
        data  = args.last.is_a?(Hash) ? args.last : {}
        state = data[:state].try(:to_sym) || target_state
        object.past_states << object.state.to_sym if object.state
        object.state = state.to_sym
        set_timestamp(object, data[:"#{target_state}_at"] || now)
      end

      def set_timestamp(object, time)
        reader, writer = :"#{target_state}_at", :"#{target_state}_at="
        return unless object.respond_to?(writer) && object.respond_to?(reader) && object.send(reader).nil?
        object.send(writer, time)
      end

      def set_state?(object, args)
        data  = args.last.is_a?(Hash) ? args.last : {}
        state = data[:state].try(:to_sym) || target_state
        return true unless object.class.state_options[:ordered]
        states = object.class.state_names
        lft, rgt = states.index(object.state.try(:to_sym)), states.index(state)
        lft.nil? || rgt.nil? || lft < rgt
      end

      def target_state
        options.to || "#{name}ed".sub(/eed$/, 'ed').to_sym
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
        object.state && object.class.state_names.include?(object.state.to_sym)
      end

      def raise_invalid_transition(object)
        raise TransitionException, "#{object.inspect} can not receive event #{name.inspect} while in state #{object.state.inspect}."
      end

      def raise_unknown_target_state(object)
        raise TransitionException, "unknown target state #{object.state.inspect} for #{object.inspect} for event #{name.inspect}. known states are #{object.class.states.inspect}"
      end
  end
end
