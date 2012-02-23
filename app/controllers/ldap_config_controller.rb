# derived from OptionsController, where most of the code is
class LdapConfigController < OptionsController
  layout "standard"

  before_filter :check_auth_mode
  before_filter :init_menu
  before_filter :set_optgroup

  def check_auth_mode
    if ! Auth.ldap_enabled?()
      redirect_to :controller => "info", :action => "list"
      return false
    end
  end

  def init_menu
    @menus.set_selected("ldap")
    @menus.set_selected("ldap_config")
  end

  def set_optgroup
    @optgroup = "ldap_options"
  end
end
