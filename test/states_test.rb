require 'test_helper'
require 'active_support/core_ext/time/zones'

class StatesTest < Minitest::Test
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
    klass = Class.new do
      include SimpleStates
      attr_accessor :state

      event :start
      def start
        self.state = :running
      end
    end
    assert_raises(SimpleStates::TransitionException) { klass.new.start }
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

  test "[state]? predicates defined on the class body take precedence" do
    klass = Class.new do
      include SimpleStates
      attr_accessor :state
      def created?; false; end
    end
    object = klass.new

    assert !object.created?
  end

  test "was_[state]? predicates" do
    object = create_class { event :start, :from => :created, :to => :started }.new

    assert object.was_created?
    assert !object.was_started?

    object.start

    assert object.was_created?
    assert object.was_started?
  end

  test "[state]_at is set if a writer is defined and timestamp passed" do
    now = Time.now.tap { |now| Time.stubs(:now).returns(now) }
    object = create_class { event :start, :from => :created, :to => :started }.new
    object.singleton_class.send(:attr_accessor, :started_at)
    object.start(started_at: now - 60)
    assert_equal now - 60, object.started_at
  end

  test "[state]_at is set if a writer is defined and no timestamp passed" do
    now = Time.now.tap { |now| Time.stubs(:now).returns(now) }
    object = create_class { event :start, :from => :created, :to => :started }.new
    object.singleton_class.send(:attr_accessor, :started_at)
    object.start
    assert_equal now, object.started_at
  end

  test 'can pass arbitrary attributes' do
    object = create_class { states :started; event :start }.new
    object.singleton_class.send(:attr_accessor, :foo)
    object.start(foo: true)
    assert object.foo
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

    klass.new
    first, second = klass.events
    assert_equal [:notify, :prepare], first.last[:before]
    assert_equal [:notify, :cleanup], second.last[:before]
  end

  test "merge_events (:all second)" do
    klass = create_class do
      event :start, :to => :started, :before => :prepare
      event :all, :before => :notify
      event :finish, :to => :finished, :before => :cleanup
    end

    klass.new
    first, second = klass.events
    assert_equal [:prepare, :notify], first.last[:before]
    assert_equal [:notify, :cleanup], second.last[:before]
  end

  test "merge_events (:all last)" do
    klass = create_class do
      event :start, :to => :started, :before => :prepare
      event :finish, :to => :finished, :before => :cleanup
      event :all, :before => :notify
    end

    klass.new
    first, second = klass.events
    assert_equal [:prepare, :notify], first.last[:before]
    assert_equal [:cleanup, :notify], second.last[:before]
  end

  test "set custom state in event callback" do
    klass = Class.new do
      include SimpleStates
      attr_accessor :state

      states :passed, :failed
      event :finish

      def finish
        self.state = :passed
      end
    end

    object = klass.new
    object.finish
    assert_equal :passed, object.state
  end

  test "set state through given data" do
    klass = create_class do
      states :passed, :failed
      event :finish
    end

    object = klass.new
    object.finish(state: :passed)
    assert_equal :passed, object.state
  end

  test "returns true when the event was processed" do
    klass = create_class do
      states :created, :started
      event :start
    end

    object = klass.new
    assert_equal object.start, true
  end

  test "returns false when the event was skipped via condition" do
    klass = Class.new do
      include SimpleStates
      attr_accessor :state

      states :created, :started
      event :start, if: :start?

      def start?; false; end
    end

    object = klass.new
    assert_equal object.start, false
  end

  test "returns false when the event was skipped via ordered states" do
    klass = create_class do
      states :created, :started, :finished, ordered: true
      event :start
      event :finish
    end

    object = klass.new
    object.finish
    assert_equal object.start, false
  end
end
