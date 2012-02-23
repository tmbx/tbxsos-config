require File.dirname(__FILE__) + '/../test_helper'
require 'keys_controller'

# Re-raise errors caught by the controller.
class KeysController; def rescue_action(e) raise e end; end

class KeysControllerTest < Test::Unit::TestCase
  def setup
    @controller = KeysController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
