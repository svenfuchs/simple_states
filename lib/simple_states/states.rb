module SimpleStates
  class States < Module
    class << self
      def init(object)
        object.singleton_class.send(:include, proxy_for(object.class))
        if object.singleton_class.respond_to?(:after_initialize)
          object.singleton_class.after_initialize { self.state = self.class.initial_state if state.blank? }
        else
          object.state = object.class.initial_state
        end
      end

      def proxy_for(klass)
        args = [:States].concat(klass.method(:const_defined?).arity != 1 ? [false] : [])
        klass.const_defined?(*args) ? klass::States : klass.const_set(:States, new(klass.events))
      end
    end

    def initialize(events)
      merge_events(events).each do |event|
        define_event(event)
      end
    end

    protected

      def define_event(event)
        define_method(event.name) do |*args|
          event.send(:call, self, *args) do
            super(*args) if self.class.method_defined?(event.name)
          end
        end

        define_method(:"#{event.name}!") do |*args|
          event.saving do
            send(event.name, *args)
          end
        end
      end

      def merge_events(events)
        merges, events = *events.partition { |event| event.name == :all }
        events.each { |event| merges.each { |merge| event.merge(merge) } }
      end
  end
end
