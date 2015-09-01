require 'test_helper'

class CustomInitialStateTest < Minitest::Test
  class Stateful
    include SimpleStates

    attr_accessor :state

    states :unconfirmed, :confirmed, :rejected, :deployed, :missing

    self.initial_state = :unconfirmed

    event :confirm, :to => :confirmed
    event :reject,  :to => :rejected

    event :deploy,  :to => :deployed
    event :scratch, :to => :missing
    event :recover, :to => :deployed
  end

  test "assumes :created as default initial state" do
    assert_equal :unconfirmed, Stateful.initial_state

    obj = Stateful.new
    assert_equal :unconfirmed, obj.state

    obj.confirm
    assert_equal :confirmed, obj.state

    obj.reject
    assert_equal :rejected, obj.state
  end
end
