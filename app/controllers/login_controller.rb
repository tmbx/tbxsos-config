# -*- coding: utf-8 -*-
# login_controller.rb
# Copyright (C) 2007-2012 Opersys inc., All rights reserved.
#
# Login controller
#
# @author François-Denis Gonthier

class LoginController < ApplicationController
  layout "standard"

  skip_before_filter :login_done
  skip_before_filter :dispatch

  # Pushes the user to the organization list if the password he provides is correct.
  def login
    o = ConfigOptions.new

    if o.get("server.password") == ""
      flash[:error] = GTEH_("login.failed.empty_password")
      redirect_to :action => 'index', :controller => 'index'
    elsif params[:login][:password] == o.get("server.password")
      session[:ok] = true
      session[:backlink] = []
      redirect_to :action => 'list', :controller => 'info'
    else
      flash[:error] = GTEH_("login.failed")
      redirect_to :action => 'index', :controller => 'index'
    end
  end

  def logout
    session[:ok] = false
    redirect_to :action => 'index', :controller => 'index'
  end
end
