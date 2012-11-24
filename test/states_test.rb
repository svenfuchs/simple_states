require 'test_helper'
require 'active_support/core_ext/time/zones'

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

  test "tries to look up a target state from the states list unless given as a :to option" do
    object = create_class { states :started; event :start }.new
    object.start
    assert object.state?(:started)
  end

  test "raises TransitionException if no :to option is given and the state can not be derived from the states list" do
    object = create_class { event :start }.new
    assert_raises(SimpleStates::TransitionException) { object.start }
  end

  test "doesn't raise TransitionException if the state is persisted as a string" do
    klass = create_class { states :created, :started; event :start, :from => :created, :to => :started }
    klass.class_eval { def state=(state); @state = state.to_s; end }

    object = klass.new

    assert_nothing_raised(SimpleStates::TransitionException) { object.start }
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

  # test "set_state sets the state manually" do
  #   object = create_class { states :mockiewocked }.new
  #   object.set_state(:mockiewocked)
  #   assert object.mockiewocked?
  # end

  test "allows setting the eventual state in the event method" do
    klass = create_class do
      states :cancelled
      event :finish
      define_method(:finish) { self.state = :cancelled }
    end
    object = klass.new
    object.finish
    assert_equal :cancelled, object.state
  end

  test "merge_events (:all first)" do
    klass = create_class do
      event :all, :before => :notify
      event :start, :to => :started, :before => :prepare
      event :finish, :to => :finished, :before => :cleanup
    end

    first, second = SimpleStates::States.new(klass.events).events
    assert_equal [:notify, :prepare], first.options[:before]
    assert_equal [:notify, :cleanup], second.options[:before]
  end

  test "merge_events (:all second)" do
    klass = create_class do
      event :start, :to => :started, :before => :prepare
      event :all, :before => :notify
      event :finish, :to => :finished, :before => :cleanup
    end

    first, second = SimpleStates::States.new(klass.events).events
    assert_equal [:prepare, :notify], first.options[:before]
    assert_equal [:notify, :cleanup], second.options[:before]
  end

  test "merge_events (:all last)" do
    klass = create_class do
      event :start, :to => :started, :before => :prepare
      event :finish, :to => :finished, :before => :cleanup
      event :all, :before => :notify
    end

    first, second = SimpleStates::States.new(klass.events).events
    assert_equal [:prepare, :notify], first.options[:before]
    assert_equal [:cleanup, :notify], second.options[:before]
  end
end
