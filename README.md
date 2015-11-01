# simple\_states [![Build Status](https://secure.travis-ci.org/svenfuchs/simple_states.png)](http://travis-ci.org/svenfuchs/simple_states)

A super-slim (~200 loc) statemachine-like support library focussed on use in
Travis CI.

Note that the current version behaves slightly differently, and comes with
reduced features compared to the original version. If you are looking for the
original version see the tag `v1.1.0.rc11`.

## Usage

Define states and events like this:

``` ruby
class Foo
  include SimpleStates

  event :start,  if: :start?
  event :finish, to: [:passed, :failed], after: :notify, unless: :finished?

  attr_accessor :state, :started_at, :finished_at

  def start
    # start foo
  end

  def start?
    true
  end

  def notify(event)
    # notify about event on foo
  end
end
```

SimpleStates expects your model to support attribute accessors for `:state`.

Event options have the following well-known meanings:

``` ruby
:to     # allowed target states to transition to, deferred from the event name if not given
:if     # only proceed if the given method returns true
:unless # only proceed if the given method returns false
:before # run the given method before running `super` and setting the new state
:after  # run the given method at the very end
```

All of these options except can be given as a single symbol or string or as an
Array of symbols or strings.

Calling `event` will effectively add methods to a proxy module which is
prepended to your class (included to the singleton class of your class'
instances on 1.9). E.g. declaring `event :start` in the example above will add
methods `start` and `start!` to a module included to the singleton class of
instances of `Foo`.

This method will

1. check if `:if`/`:unless` conditions apply (if given) and just return from the method otherwise
2. run `:before` callbacks (if given)
3. set the object's `state` to the target state
4. set the object's `[state]_at` attribute to `Time.now` if the object defines a writer for it
5. call `super` if Foo defines the current method (i.e. call `start` but not `finish` in the example above)
6. run `:after` callbacks (if given)

You can define options for all events like so:

``` ruby
event :finish, after: :cleanup
event :all,    after: :notify
```

This will call :cleanup first and then :notify on :finish.

If no target state was given for an event then SimpleStates will try to derive
it from the event name. I.e. for an event `start` it will check the states
list for a state `started` and use it. If it can not find a target state this
way then it will raise an exception.

