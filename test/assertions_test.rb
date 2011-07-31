require 'test_helper'

class AssertionsTest < Test::Unit::TestCase
  include ClassCreateHelper

  test "raises an exception if an event is received when the object not in the expected state" do
    klass = create_class do
      event :start, :from => :created, :to => :started
    end

    object = klass.new
    object.state = :started

    assert_raises(SimpleStates::TransitionException) do
      object.start
    end
  end
end

