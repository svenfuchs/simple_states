require 'test_helper'

class AssertionsTest < Test::Unit::TestCase
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

  test "sets @saving back to falls when an expception is raised" do
    klass = create_class do
      event :error, :from => [:started, :warning], :to => :errored

      define_method(:save!) do |*args|
        raise StandardError
      end
    end

    object = klass.new
    object.state = :started
    event = klass.events.first

    assert_raises(StandardError) do
      object.error!
    end

    assert_equal event.instance_variable_get(:@saving), false
  end
end

