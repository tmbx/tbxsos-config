class LegalController < ApplicationController
  layout "standard"

  before_filter :init_menu

  # does not work in initialize
  def init_menu
    @menus.set_selected("legal")
  end

  def list
  end

end
