require 'simple_states/event'
require 'simple_states/helpers'

module SimpleStates
  class States < Module
    include Helpers

    def events
      @events ||= {}
    end

    def states
      events.values.map { |event| event.opts[:to] }.flatten.compact
    end

    def define_event(name, opts)
      events[name] = Event.new(name, { to: to_past(name).to_sym }.merge(opts))

      send(:define_method, name) do |data = {}, opts = {}|
        self.class::States.events[name].call(self, data, opts) do
          if method(name).respond_to?(:super_method)
            supa = method(name).super_method
            supa.call(*[name, data].slice(0, supa.arity.abs)) if supa
          elsif defined?(super)
            super(name, data)
          end
        end
      end

      send(:define_method, :"#{name}!") do |data = {}|
        send(name, data, save: true)
      end
    end

    def update_events(_, opts)
      events.values.each do |event|
        opts.each do |key, value|
          event.opts[key] = Array(event.opts[key]).concat(Array(value))
        end
      end
    end
  end
end
