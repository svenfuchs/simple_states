require 'test_helper'

class CancellationTest < Test::Unit::TestCase
  include ClassCreateHelper

  test "Class.event wraps a method with cancellation callbacks (if: arity 0)" do
    klass = create_class do
      event :start, :from => :created, :to => :started, :if => :approve?
      define_method(:approve?) { true }
    end

    object = klass.new
    object.start(:foo, :bar)

    assert object.started?
  end

  test "Class.event wraps a method with cancellation callbacks (if: arity 1)" do
    klass = create_class do
      event :start, :from => :created, :to => :started, :if => :approve?
      define_method(:approve?) { |arg| @received_arg = arg; true }
    end

    object = klass.new
    object.start(:foo, :bar)

    assert object.started?
    assert object.instance_variable_get(:@received_arg).is_a?(SimpleStates::Event)
  end

  test "Class.event wraps a method with cancellation callbacks (if: arity -1)" do
    klass = create_class do
      event :start, :from => :created, :to => :started, :if => :approve?
      define_method(:approve?) { |*args| @received_args = args; true }
    end

    object = klass.new
    object.start(:foo, :bar)

    assert object.started?
    assert_equal 3, object.instance_variable_get(:@received_args).size
  end

  test "Class.event wraps a method with cancellation callbacks (except: arity 0)" do
    klass = create_class do
      event :start, :from => :created, :to => :started, :except => :cancel?
      define_method(:cancel?) { true }
    end

    object = klass.new
    object.start(:foo, :bar)

    assert !object.started?
    assert_equal :created, object.state
  end

  test "Class.event wraps a method with cancellation callbacks (except: arity 1)" do
    klass = create_class do
      event :start, :from => :created, :to => :started, :except => :cancel?
      define_method(:cancel?) { |arg| @received_arg = arg; true }
    end

    object = klass.new
    object.start(:foo, :bar)

    assert !object.started?
    assert_equal :created, object.state
  end

  test "Class.event wraps a method with cancellation callbacks (except: arity -1)" do
    klass = create_class do
      event :start, :from => :created, :to => :started, :except => :cancel?
      define_method(:cancel?) { |*args| @received_args = args; true }
    end

    object = klass.new
    object.start(:foo, :bar)

    assert !object.started?
    assert_equal :created, object.state
  end
end
