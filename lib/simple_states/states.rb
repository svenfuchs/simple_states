module SimpleStates
  class States < Module
    class << self
      def init(object)
        object.class.state_names = [object.class.initial_state] if object.class.state_names.empty?
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
          const.state_names.each { |name| define_state(mod, name) }
        end
      end

      def define_event(const, (name, options))
        const.send(:define_method, name) do |*args|
          event = args.first.is_a?(Event) ? args.shift : Event.new(name, options)
          event.call(self, *args) { defined?(super) ? super(*args) : true }
        end

        const.send(:define_method, :"#{name}!") do |*args|
          send(name, Event.new(name, options.merge(save: true)), *args)
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
        return events unless other_ix = events.index { |event| event.first == :all }
        other = events.slice!(other_ix)
        events.each_with_index do |event, ix|
          merge_event(event, other, ix < other_ix)
        end
        merge_events(events)
      end

      def merge_event(event, other, append = true)
        other.last.each do |key, value|
          event.last[key] = [event.last[key]].send(append ? :push : :unshift, value).compact.flatten
        end
      end
    end
  end
end
