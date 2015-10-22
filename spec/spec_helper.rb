require 'simple_states'
require 'support/helpers'

RSpec.configure do |c|
  c.mock_with :mocha
  c.include Support::Helpers
end
