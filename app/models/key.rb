# -*- coding: utf-8 -*-
# key.rb
# Copyright (C) 2007-2012 Opersys inc., All rights reserved.
#
# Key model
#
# @author François-Denis Gonthier

class Key < ActiveRecord::Base
  set_table_name 'public_key'
  set_primary_key 'key_id'

  has_one :enc_pkey, :class_name => "EncPKey", :foreign_key => 'key_id'
end
