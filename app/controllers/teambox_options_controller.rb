class TeamboxOptionsController < OptionsController
  layout "standard"

  before_filter :init_menu
  def init_menu
    @menus.set_selected("teambox")
    @menus.set_selected("teambox_identity")
  end

  before_filter :set_optgroup
  def set_optgroup
    @optgroup = "identities_options"
  end
end
