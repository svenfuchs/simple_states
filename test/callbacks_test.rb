require 'test_helper'

class CallbacksTest < Test::Unit::TestCase
  include ClassCreateHelper

  test "before callback (arity 0)" do
    klass = create_class do
      event :start, :from => :created, :to => :started, :before => :prepare
      define_method(:prepare) { @prepared = true }
    end

    object = klass.new
    object.start

    assert object.instance_variable_get(:@prepared)
  end

  test "before callback (arity 1)" do
    klass = create_class do
      event :start, :from => :created, :to => :started, :before => :prepare
      define_method(:prepare) { |arg| @received_arg = arg; @prepared = true }
    end

    object = klass.new
    object.start(:foo, :bar)

    assert object.instance_variable_get(:@prepared)
    assert_equal :start, object.instance_variable_get(:@received_arg)
  end

  test "before callback (arity -1)" do
    klass = create_class do
      event :start, :from => :created, :to => :started, :before => :prepare
      define_method(:prepare) { |*args| @received_args = args; @prepared = true }
    end

    object = klass.new
    object.start(:foo, :bar)

    assert object.instance_variable_get(:@prepared)
    assert_equal 3, object.instance_variable_get(:@received_args).size
  end

  test "multiple before callbacks" do
    klass = create_class do
      event :start, :from => :created, :to => :started, :before => [:prepare, :notify]
      define_method(:prepare) { @prepared = true }
      define_method(:notify)  { @notified = true }
    end

    object = klass.new
    object.start

    assert object.instance_variable_get(:@prepared)
    assert object.instance_variable_get(:@notified)
  end

  test "after callback (arity 0)" do
    klass = create_class do
      event :start, :from => :created, :to => :started, :after => :cleanup
      define_method(:cleanup) { @cleaned = true }
    end

    object = klass.new
    object.start

    assert object.instance_variable_get(:@cleaned)
  end

  test "after callback (arity 1)" do
    klass = create_class do
      event :start, :from => :created, :to => :started, :after => :cleanup
      define_method(:cleanup) { |arg| @received_arg = arg; @cleaned = true }
    end

    object = klass.new
    object.start(:foo, :bar)

    assert object.instance_variable_get(:@cleaned)
    assert_equal :start, object.instance_variable_get(:@received_arg)
  end

  test "after callback (arity -1)" do
    klass = create_class do
      event :start, :from => :created, :to => :started, :after => :cleanup
      define_method(:cleanup) { |*args| @received_args = args; @cleaned = true }
    end

    object = klass.new
    object.start(:foo, :bar)

    assert object.instance_variable_get(:@cleaned)
    assert_equal 3, object.instance_variable_get(:@received_args).size
  end

  test "multiple after callbacks" do
    klass = create_class do
      event :start, :from => :created, :to => :started, :after => [:cleanup, :notify]
      define_method(:cleanup) { @cleaned  = true }
      define_method(:notify)  { @notified = true }
    end

    object = klass.new
    object.start

    assert object.instance_variable_get(:@cleaned)
    assert object.instance_variable_get(:@notified)
  end
end
