require 'test_helper'

class AssertionsTest < Minitest::Test
  include ClassCreateHelper

  test "does not raise an exception if an event is received when the object is in the expected state (single :from state)" do
    klass = create_class do
      event :error, :from => :started, :to => :errored
    end

    object = klass.new
    object.state = :started

    assert_nothing_raised(SimpleStates::TransitionException) do
      object.error
    end
  end

  test "does not raise an exception if an event is received when the object is in one of the expected states (multiple :from states using :all)" do
    klass = create_class do
      event :error, :from => :started, :to => :errored
      event :all, :from => :warning
    end

    object = klass.new
    object.state = :warning

    assert_nothing_raised(SimpleStates::TransitionException) do
      object.error
    end
  end

  test "does not raise an exception if an event is received when the object is in one of the expected states (multiple :from states using from: [])" do
    klass = create_class do
      event :error, :from => [:started, :warning], :to => :errored
    end

    object = klass.new
    object.state = :warning

    assert_nothing_raised(SimpleStates::TransitionException) do
      object.error
    end
  end

  test "raises an exception if an event is received when the object is not in the expected state (single :from state)" do
    klass = create_class do
      event :error, :from => :started, :to => :errored
    end

    object = klass.new
    object.state = :initialized

    assert_raises(SimpleStates::TransitionException) do
      object.error
    end
  end

  test "raises an exception if an event is received when the object is not in any of the expected states (multiple :from states using :all)" do
    klass = create_class do
      event :error, :from => :started, :to => :errored
      event :all, :from => :warning
    end

    object = klass.new
    object.state = :initialized

    assert_raises(SimpleStates::TransitionException) do
      object.error
    end
  end
end

