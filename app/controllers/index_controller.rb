# -*- coding: utf-8 -*-
# index_controller.rb
# Copyright (C) 2007-2012 Opersys inc., All rights reserved.
#
# Entry point
#
# @author François-Denis Gonthier

class IndexController < ApplicationController
  layout "login"

  # This is the only place access is allowed
  skip_before_filter :login_done
  skip_before_filter :dispatch
end
