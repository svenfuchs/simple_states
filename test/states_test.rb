require 'test_helper'

class StatesTest < Test::Unit::TestCase
  include ClassCreateHelper

  test "assumes :created as default initial state" do
    object = create_class.new

    assert_equal :created, object.state
    assert object.created?
  end

  test "uses a custom initial state" do
    object = create_class { states :initial => :started }.new

    assert_equal :started, object.state
    assert object.started?
  end

  test "state? returns true if the object has the given state" do
    object = create_class { event :start, :from => :created, :to => :started }.new

    assert object.state?(:created)
    assert !object.state?(:started)

    object.start

    assert !object.state?(:created)
    assert object.state?(:created, true)
    assert object.state?(:started)
  end

  test "was_state? returns true if the object has or ever had the given state" do
    object = create_class { event :start, :from => :created, :to => :started }.new

    assert object.was_state?(:created)
    assert !object.was_state?(:started)

    object.start

    assert object.was_state?(:created)
    assert object.was_state?(:started)
  end

  test "responds to [state]? if the class defines this state" do
    object = create_class { states :started }.new

    assert object.respond_to?(:created?)
    assert object.respond_to?(:started?)
    assert !object.respond_to?(:finished?)
  end

  test "[state]? predicates" do
    object = create_class { event :start, :from => :created, :to => :started }.new

    assert object.created?
    assert !object.started?

    object.start

    assert !object.created?
    assert object.created?(true)
    assert object.started?
  end

  test "was_[state]? predicates" do
    object = create_class { event :start, :from => :created, :to => :started }.new

    assert object.was_created?
    assert !object.was_started?

    object.start

    assert object.was_created?
    assert object.was_started?
  end

  test "[state]_at is set if a writer is defined" do
    now = Time.now.tap { |now| Time.stubs(:now).returns(now) }
    object = create_class { event :start, :from => :created, :to => :started }.new
    object.singleton_class.send(:attr_accessor, :started_at)
    object.start
    assert_equal now, object.started_at
  end
end
