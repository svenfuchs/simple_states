module SimpleStates
  module Helpers
    def to_past(string)
      "#{string}ed".sub(/eed$/, 'ed')
    end
  end
end
