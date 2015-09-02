require 'test_helper'

class StatesTest < Minitest::Test
  include ClassCreateHelper

  test 'advances from :started to :finished' do
    object = create_class { states :started, :finished, ordered: true; event :start; event :finish }.new
    object.start
    assert_equal :started, object.state
    object.finish
    assert_equal :finished, object.state
  end

  test 'does not revert from :finished to :started' do
    object = create_class { states :started, :finished, ordered: true; event :start; event :finish }.new
    object.finish
    assert_equal :finished, object.state
    object.start
    assert_equal :finished, object.state
  end
end
