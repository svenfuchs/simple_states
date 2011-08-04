# simple\_states [![Build Status](https://secure.travis-ci.org/svenfuchs/simple_states.png)](http://travis-ci.org/svenfuchs/simple_states)

A super-slim (~200 loc) statemachine-like support library focussed on use in
Travis CI.

## Usage

Define states and events like this:

    class Foo
      include SimpleStates

      states :created, :started, :finished

      event :start,  :from => :created, :to => :started,  :if => :startable?
      event :finish, :to => :finished, :after => :cleanup

      attr_accessor :state, :started_at, :finished_at

      def start
        # start foo
      end

      def startable?
        true
      end

      def cleanup
        # cleanup foo
      end
    end

Including the SimpleStates module to your class is currently required. We'll add
hooks for ActiveRecord etc later.

SimpleStates expects your model to support attribute accessors for `:state`.

Event options have the following well-known meanings:

    :from   # valid states to transition from
    :to     # target state to transition to
    :if     # only proceed if the given method returns true
    :unless # only proceed if the given method returns false
    :before # run the given method before running `super` and setting the new state
    :after  # run the given method at the very end

All of these options except for `:to` can be given as a single symbol or string or
as an Array of symbols or strings.

Calling `event` will effectively add methods to a proxy module which is
included to the singleton class of your class' instances. E.g. declaring `event
:start` in the example above will add a method `start` to a module included to
the singleton class of instances of `Foo`.

This method will

1. check if `:if`/`:except` conditions apply (if given) and just return from the method otherwise
2. check if the object currently is in a valid `:from` state (if given) and raise an exception otherwise
3. run `:before` callbacks (if given)
4. call `super` if Foo defines the current method (i.e. call `start` but not `finish` in the example above)
5. add the object's current state to its `past_states` history
6. set the object's `state` to the target state given as `:to`
7. set the object's `[state]_at` attribute to `Time.now` if the object defines a writer for it
8. run `:after` callbacks (if given)

You can define options for all events like so:

    event :finish, :to => :finished, :after => :cleanup
    event :all, :after => :notify

This will call :cleanup first and then :notify on :finish.

If no target state was given for an event then SimpleStates will try to derive
it from the states list. I.e. for an event `start` it will check the states
list for a state `started` and use it. If it can not find a target state this
way then it will raise an exception.

By default SimpleStates will assum `:created` as an initial state. You can
overwrite this using:

    self.initial_state :something

So with the example above something the following would work:

    foo = Foo.new

    foo.state            # :created
    foo.created?         # true
    foo.was_created?     # true
    foo.state?(:created) # true

    foo.start            # checks Foo#startable? and then calls Foo#start

    foo.state            # :started
    foo.started?         # true
    foo.started_at       # Time.now
    foo.created?         # false
    foo.was_created?     # true

    foo.finish           # just performs state logic as there's no Foo#finish

    foo.state            # :finished
    foo.finished?        # true
    foo.finished_at      # Time.now
    foo.was_created?     # true
    foo.was_started?     # true


