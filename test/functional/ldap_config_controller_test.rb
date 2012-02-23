require File.dirname(__FILE__) + '/../test_helper'
require 'ldap_config_controller'

# Re-raise errors caught by the controller.
class LDAPConfigController; def rescue_action(e) raise e end; end

class LDAPConfigControllerTest < Test::Unit::TestCase
  def setup
    @controller = LDAPConfigController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
