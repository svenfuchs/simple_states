require 'test_helper'

class SimpleStatesTest < Test::Unit::TestCase
  include ClassCreateHelper

  test "Class.states announces states the class supports" do
    klass = create_class { states :created, :started, :completed }
    assert_equal [:created, :started, :completed], klass.states
  end

  test "Class.event wraps a method with state progression" do
    object = create_class { event :start, :from => :created, :to => :started }.new
    object.start

    assert object.started?
    assert_equal :started, object.state
  end
end

