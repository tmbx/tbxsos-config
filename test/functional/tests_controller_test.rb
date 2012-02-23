require File.dirname(__FILE__) + '/../test_helper'
require 'tests_controller'

# Re-raise errors caught by the controller.
class TestsController; def rescue_action(e) raise e end; end

class TestsControllerTest < Test::Unit::TestCase
  def setup
    @controller = TestsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
