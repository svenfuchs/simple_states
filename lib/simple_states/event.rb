require 'active_support/core_ext/module/delegation'
require 'hashr'

module SimpleStates
  class Event
    attr_reader :name, :options

    def initialize(name, options = {})
      @name    = name
      @options = Hashr.new(options) do
        def except
          self[:except]
        end
      end
    end

    def call(object, *args)
      return if skip?(object, args)

      run_callback(before, object, args) if options.before?
      assert_transition(object)

      result = yield if object.class.method_defined?(name)

      set_state(object) if options.to
      run_callback(options.after) if options.after?

      result
    end

    protected

      def skip?(object, args)
        result = false
        result ||= !send_method(options.if, object, *args) if options.if?
        result ||= send_method(options.except, object, *args) if options.except?
        result
      end

      def send_method(method, object, *args)
        object.send method, *case arity = object.class.instance_method(method).arity
          when 0;  []
          when -1; [self].concat(args)
          else;    [self].concat(args).slice(0..arity - 1)
        end
      end
      alias :run_callback :send_method

      def assert_transition(object)
        # assert transition is allowed
      end

      def set_state(object)
        object.past_states << object.state
        object.state = options.to
      end
  end
end
