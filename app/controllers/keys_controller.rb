# -*- coding: utf-8 -*-
# index_controller.rb
# Copyright (C) 2007-2012 Opersys inc., All rights reserved.
#
# Entry point
#
# @author François-Denis Gonthier

class KeysController < ApplicationController
  layout "standard"

  def list
    @keys = Key.find(:all)
  end
end
