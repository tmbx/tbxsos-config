# -*- coding: utf-8 -*-
# email.rb
# Copyright (C) 2007-2012 Opersys inc., All rights reserved.
#
# Group profile model
#
# @author François-Denis Gonthier

class EncPKey < ActiveRecord::Base
  set_table_name "enc_key"
  set_primary_key "key_id"
end
