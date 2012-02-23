# -*- coding: utf-8 -*-
# key.rb
# Copyright (C) 2007-2012 Opersys inc., All rights reserved.
#
# LDAP Group model
#
# @author François-Denis Gonthier

class LdapGroup < ActiveRecord::Base
  set_table_name 'ldap_groups'
  set_primary_key 'ldap_group_id'
  set_sequence_name 'ldap_group_id_seq'

  belongs_to :group, {
    :class_name => 'GroupProfil',
    :foreign_key => 'group_id'
  }
end
