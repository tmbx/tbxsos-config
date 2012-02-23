# -*- coding: utf-8 -*-
# about_controller.rb
# Copyright (C) 2007-2012 Opersys inc., All rights reserved.
#
# About screen
#
# @author François-Denis Gonthier

class AboutController < ApplicationController
  layout "standard"

  before_filter :init_menu

  # does not work in initialize
  def init_menu
    @menus.set_selected("about")
  end

  def list
    @about_content = GTEH_("about") % '<a href="http://www.teambox.co">www.teambox.co</a>'
  end
end
