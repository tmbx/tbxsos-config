# -*- coding: utf-8 -*-
# email.rb
# Copyright (C) 2007-2012 Opersys inc., All rights reserved.
#
# Email model
#
# @author François-Denis Gonthier

class Email < ActiveRecord::Base
  set_table_name 'emails'
  set_primary_key 'email_id'
  set_sequence_name 'email_id_seq'

  belongs_to :user, {
    :class_name => 'UserProfil',
    :foreign_key => 'user_id'
  }
end
