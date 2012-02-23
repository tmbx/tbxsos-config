# errors_controller.rb
# Copyright (C) 2007-2012 Opersys inc., All rights reserved.
#
# Errors
#
# @author Mathieu Martin

class ErrorsController < ApplicationController
  layout "error"

  # does not work in initialize
  def _404
    render :action => "404"
  end

  #def _500
  #end
end
