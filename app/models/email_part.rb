# -*- coding: utf-8 -*-
# email.rb
# Copyright (C) 2007-2012 Opersys inc., All rights reserved.
#
# Email Part model
#
# @author François-Denis Gonthier

class EmailPart < ActiveRecord::Base
  set_table_name 'email_parts'
  set_primary_key 'email_part_id'
  set_sequence_name 'email_part_id_seq'

  belongs_to :group, {
    :class_name => 'GroupProfil',
    :foreign_key => 'group_id'
  }
end
