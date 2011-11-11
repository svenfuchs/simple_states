module SimpleStates
  class States < Module
    class << self
      def init(object)
        object.singleton_class.send(:include, proxy_for(object.class))
        object.init_state unless object.singleton_class.respond_to?(:after_initialize)
      end

      def proxy_for(klass)
        args = [:StatesProxy].concat(klass.method(:const_defined?).arity != 1 ? [false] : [])
        klass.const_defined?(*args) ? klass::StatesProxy : klass.const_set(:StatesProxy, new(klass.events))
      end
    end

    attr_reader :events

    def initialize(events)
      @events = merge_events(events)
      setup
    end

    protected

      def setup
        events.each do |event|
          define_event(event)
        end
      end


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
        if merge_ix = events.index { |event| event.name == :all }
          merge = events.slice!(merge_ix)
          events.each_with_index do |event, ix|
            # method =  ? :append : :prepend

            event.merge(merge, ix < merge_ix)
          end
          merge_events(events)
        else
          events
        end
      end
  end
end
