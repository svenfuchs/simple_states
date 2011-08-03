require 'test_helper'

class ConditionsTest < Test::Unit::TestCase
  include ClassCreateHelper

  test "processes the event if the :if callback applies (arity 0)" do
    klass = create_class do
      event :start, :from => :created, :to => :started, :if => :approve?
      define_method(:approve?) { true }
    end

    object = klass.new
    object.start(:foo, :bar)

    assert object.started?
  end

  test "processes the event if the :if callback applies (arity 1)" do
    klass = create_class do
      event :start, :from => :created, :to => :started, :if => :approve?
      define_method(:approve?) { |arg| @received_arg = arg; true }
    end

    object = klass.new
    object.start(:foo, :bar)

    assert object.started?
    assert_equal :start, object.instance_variable_get(:@received_arg)
  end

  test "processes the event if the :if callback applies (arity -1)" do
    klass = create_class do
      event :start, :from => :created, :to => :started, :if => :approve?
      define_method(:approve?) { |*args| @received_args = args; true }
    end

    object = klass.new
    object.start(:foo, :bar)

    assert object.started?
    assert_equal 3, object.instance_variable_get(:@received_args).size
  end

  test "does not process the event if the :if callback applies" do
    klass = create_class do
      event :start, :from => :created, :to => :started, :if => :approve?
      define_method(:approve?) { false }
    end

    object = klass.new
    object.start(:foo, :bar)

    assert !object.started?
    assert_equal :created, object.state
  end

  test "does not process the event if the :except callback applies (arity 0)" do
    klass = create_class do
      event :start, :from => :created, :to => :started, :except => :cancel?
      define_method(:cancel?) { true }
    end

    object = klass.new
    object.start(:foo, :bar)

    assert !object.started?
    assert_equal :created, object.state
  end

  test "does not process the event if the :except callback applies (arity 1)" do
    klass = create_class do
      event :start, :from => :created, :to => :started, :except => :cancel?
      define_method(:cancel?) { |arg| @received_arg = arg; true }
    end

    object = klass.new
    object.start(:foo, :bar)

    assert !object.started?
    assert_equal :created, object.state
  end

  test "does not process the event if the :except callback applies (arity -1)" do
    klass = create_class do
      event :start, :from => :created, :to => :started, :except => :cancel?
      define_method(:cancel?) { |*args| @received_args = args; true }
    end

    object = klass.new
    object.start(:foo, :bar)

    assert !object.started?
    assert_equal :created, object.state
  end

  test "processes the event if the :except callback does not apply" do
    klass = create_class do
      event :start, :from => :created, :to => :started, :except => :cancel?
      define_method(:cancel?) { false }
    end

    object = klass.new
    object.start(:foo, :bar)

    assert object.started?
    assert_equal :started, object.state
  end
end
