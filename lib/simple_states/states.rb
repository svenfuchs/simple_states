module SimpleStates
  class States < Module
    class << self
      def init(object)
        respond_to?(:prepend) ? prepend_module(object.class) : include_module(object)
        object.init_state unless object.singleton_class.respond_to?(:after_initialize)
      end

      def prepend_module(const)
        const.prepend(module_for(const)) unless const.const_defined?(:StatesProxy)
      end

      def include_module(object)
        object.singleton_class.send(:include, module_for(object.class))
      end

      def module_for(const)
        args = [:StatesProxy].concat(const.method(:const_defined?).arity != 1 ? [false] : [])
        const.const_defined?(*args) ? const::StatesProxy : const.const_set(:StatesProxy, create_module(const))
      end

      def create_module(const)
        new.tap do |mod|
          merge_events(const.events).each { |event| define_event(mod, event) }
          const.states.each { |name| define_state(mod, name) }
        end
      end

      def define_event(const, event)
        const.send(:define_method, event.name) do |*args|
          event.send(:call, self, *args) do
            super(*args) if defined?(super)
          end
        end

        const.send(:define_method, :"#{event.name}!") do |*args|
          event.saving do
            send(event.name, *args)
          end
        end
      end

      def define_state(const, state)
        const.send(:define_method, :"#{state}?") do |*args|
          defined?(super) ? super() : state?(state, *args)
        end

        const.send(:define_method, :"was_#{state}?") do |*args|
          defined?(super) ? super() : was_state?(state, *args)
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
end
