require 'test_helper'

class CustomInitialStateTest < Test::Unit::TestCase
  class Stateful
    include SimpleStates

    attr_accessor :state

    states :unconfirmed, :confirmed, :rejected, :deployed, :missing

    self.initial_state = :unconfirmed

    event :confirm, :from => :unconfirmed, :to => :confirmed
    event :reject,  :from => :confirmed,   :to => :rejected
    event :reject,  :from => :unconfirmed, :to => :rejected
    event :reject,  :from => :deployed,    :to => :rejected
    event :reject,  :from => :missing,     :to => :rejected

    event :deploy,  :from => :confirmed, :to => :deployed
    event :scratch, :from => :deployed,  :to => :missing
    event :recover, :from => :missing,   :to => :deployed
  end

  test "assumes :created as default initial state" do
    assert_equal :unconfirmed, Stateful.initial_state

    obj = Stateful.new
    assert_equal :unconfirmed, obj.state

    obj.confirm
    assert_equal :confirmed, obj.state
  end
end
