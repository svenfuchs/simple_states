module Support
  module Helpers
    def self.included(c)
      c.let!(:now) { Time.now.utc }
      c.before { Time.stubs(:now).returns(stub('now', utc: now)) }
    end

    def create_class(&block)
      Class.new(Struct.new(:state)) do
        include SimpleStates
        class_eval(&block) if block
      end
    end
  end
end
