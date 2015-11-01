module SimpleStates
  class Event < Struct.new(:name, :opts)
    MSGS = {
      invalid_state: 'If multiple target states are defined, then a valid target state must be passed as an attribute ({ state: :state }). %p given, known states: %p.',
      unknown_state: 'Unknown state %p for %p for event %p. Known states are: %p'
    }

    def call(obj, data, opts)
      return false if not ordered?(obj, data) or not applies?(obj, data)

      run_callbacks(:before, obj, data)
      set_attrs(obj, data)
      yield
      obj.save! if opts[:save]

      raise_unknown_state(obj, data) unless known_state?(obj)
      run_callbacks(:after, obj, data)
      obj.save! if opts[:save]
      true
    end

    def reset(obj)
      Array(opts[:to]).each { |state| set_attr(obj, :"#{state}_at", nil) }
    end

    private

      def run_callbacks(type, obj, data)
        send_methods(opts[type], obj, data)
      end

      def set_attrs(obj, data)
        attrs = { :"#{target_state(data)}_at" => Time.now.utc }.merge(data)
        attrs.each { |key, value| set_attr(obj, key, value) }
        obj.state = target_state(data)
      end

      def set_attr(obj, key, value)
        obj.send(:"#{key}=", value) if obj.respond_to?(:"#{key}=")
      end

      def ordered?(obj, data)
        states = obj.class.states
        states.index(obj.state).to_i <= states.index(target_state(data)).to_i
      end

      def applies?(obj, data)
        result = opts[:if].nil? || send_methods(opts[:if], obj, data)
        result and opts[:unless].nil? || !send_methods(opts[:unless], obj, data)
      end

      def target_state(data)
        to = Array(opts[:to])
        return to.first if to.size == 1
        state = data[:state].to_sym if data[:state]
        to.include?(state) ? state : raise_invalid_state(data)
      end

      def send_methods(names, obj, data)
        Array(names).inject(false) do |result, name|
          result | send_method(name, obj, data)
        end
      end

      def send_method(name, obj, data)
        obj.send(name, *[self.name, data].slice(0, obj.method(name).arity.abs))
      end

      def known_state?(obj)
        obj.class.states.include?(obj.state)
      end

      def raise_invalid_state(data)
        raise Error, MSGS[:invalid_state] % [data[:state], Array(opts[:to])]
      end

      def raise_unknown_state(obj, data)
        raise Error, MSGS[:unknown_state] % [obj.state, obj, name, obj.class.states]
      end
  end
end
