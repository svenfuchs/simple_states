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
      define_method(:prepare) { |event| @received_arg = event; @prepared = true }
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
    assert_equal [:start, :foo, :bar], object.instance_variable_get(:@received_args)
  end

  test "before callback (arity -2)" do
    klass = create_class do
      event :start, :from => :created, :to => :started, :before => :prepare
      define_method(:prepare) { |event, *args| @received_args = [event, *args]; @prepared = true }
    end

    object = klass.new
    object.start(:foo, :bar)

    assert object.instance_variable_get(:@prepared)
    assert_equal [:start, :foo, :bar], object.instance_variable_get(:@received_args)
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
      define_method(:cleanup) { |event| @received_arg = event; @cleaned = true }
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
    assert_equal [:start, :foo, :bar], object.instance_variable_get(:@received_args)
  end

  test "after callback (arity -2)" do
    klass = create_class do
      event :start, :from => :created, :to => :started, :after => :cleanup
      define_method(:cleanup) { |event, *args| @received_args = [event, args]; @cleaned = true }
    end

    object = klass.new
    object.start(:foo, :bar)

    assert object.instance_variable_get(:@cleaned)
    assert_equal [:start, [:foo, :bar]], object.instance_variable_get(:@received_args)
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

  test "multiple with event :all" do
    klass = create_class do
      event :start, :from => :created, :to => :started, :after => :cleanup
      event :all, :after => :notify
      define_method(:cleanup) { @cleaned  = true }
      define_method(:notify)  { @notified = true }
    end

    object = klass.new
    object.start

    assert object.instance_variable_get(:@cleaned)
    assert object.instance_variable_get(:@notified)
  end
end
