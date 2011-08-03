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

      assert_valid_transition(object)
      run_callback(:before, object, args)

      yield.tap do
        set_state(object)
        run_callback(:after, object, args)
        object.save! if @saving
      end
    end

    protected

      def skip?(object, args)
        result = false
        result ||= !send_method(object, options.if, args) if options.if?
        result ||= send_method(object, options.except, args) if options.except?
        result
      end

      def run_callback(type, object, args)
        send_method(object, options.send(type), args) if options.send(type)
      end

      def assert_valid_transition(object)
        if options.from && options.from != object.state
          raise TransitionException, "#{object.inspect} can not receive event #{name.inspect} while in state #{object.state.inspect}."
        end
      end

      def set_state(object)
        if state = options.to
          object.past_states << object.state if object.state
          object.state = state.to_sym
          object.send(:"#{state}_at=", Time.now) if object.respond_to?(:"#{state}_at=")
          object.save! if @saving
        end
      end

      def send_method(object, method, args)
        object.send method, *case arity = self.arity(object, method)
          when 0;  []
          when -1; [name].concat(args)
          else;    [name].concat(args).slice(0..arity - 1)
        end
      end

      def arity(object, method)
        object.class.instance_method(method).arity rescue 0
      end
  end
end
