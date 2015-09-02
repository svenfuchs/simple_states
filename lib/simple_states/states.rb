module SimpleStates
  class States < Module
    class << self
      def init(object)
        respond_to?(:prepend) ? prepend_module(object.class) : include_module(object)
        object.init_state unless object.singleton_class.respond_to?(:after_initialize)
      end

      def prepend_module(const)
        const.prepend(proxy_for(const)) unless const.const_defined?(:StatesProxy)
      end

      def include_module(object)
        object.singleton_class.send(:include, proxy_for(object.class))
      end

      def proxy_for(const)
        args = [:StatesProxy].concat(const.method(:const_defined?).arity != 1 ? [false] : [])
        const.const_defined?(*args) ? const::StatesProxy : const.const_set(:StatesProxy, new(const.events, const.states))
      end
    end

    def initialize(events, states = [])
      events = merge_events(events)
      events.each { |event| define_event(event) }
    end

    private

      def define_event(event)
        define_method(event.name) do |*args|
          event.send(:call, self, *args) do
            super(*args) if defined?(super)
          end
        end

        define_method(:"#{event.name}!") do |*args|
          event.saving do
            send(event.name, *args)
          end
        end
      end

      def merge_events(events)
        if merge_ix = events.index { |event| event.name == :all }
          merge = events.slice!(merge_ix)
          events.each_with_index do |event, ix|
            event.merge(merge, ix < merge_ix)
          end
          merge_events(events)
        else
          events
        end
      end
  end
end
