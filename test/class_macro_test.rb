require 'test_helper'

class ClassMacroTest < Minitest::Test
  include ClassCreateHelper

  test "assumes :created as default initial state" do
    assert_equal :created, create_class.initial_state
  end

  test "states announces states the class supports" do
    klass = create_class { states :created, :started, :completed }
    assert_equal [:created, :started, :completed], klass.states
  end

  test "states can set an initial state" do
    klass = create_class { states :initial => :started }
    assert_equal :started, klass.initial_state
  end

  test "event wraps a method with state progression" do
    object = create_class { event :start, :from => :created, :to => :started }.new
    object.start

    assert object.started?
    assert_equal :started, object.state
  end
end
