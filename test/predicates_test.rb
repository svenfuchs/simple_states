require 'test_helper'

class PredicatesTest < Test::Unit::TestCase
  include ClassCreateHelper

  test "adds [state]? predicates" do
    object = create_class { event :start, :from => :created, :to => :started }.new

    assert object.created?
    assert !object.started?

    object.start

    assert !object.created?
    assert object.created?(true)
    assert object.started?
  end

  test "adds was_[state]? predicates" do
    object = create_class { event :start, :from => :created, :to => :started }.new

    assert object.was_created?
    assert !object.was_started?

    object.start

    assert object.was_created?
    assert object.was_started?
  end
end
