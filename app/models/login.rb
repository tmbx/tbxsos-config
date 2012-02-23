# -*- coding: utf-8 -*-
# login.rb
# Copyright (C) 2007-2012 Opersys inc., All rights reserved.
#
# Login model
#
# @author François-Denis Gonthier

class Login < ActiveRecord::Base
  set_table_name 'user_login'
  set_primary_key 'user_name'
end
