# -*- coding: utf-8 -*-
# email.rb
# Copyright (C) 2007-2012 Opersys inc., All rights reserved.
#
# Group profile model
#
# @author François-Denis Gonthier

class GroupProfil < ActiveRecord::Base
  set_table_name "group_profiles"
  set_primary_key "group_id"
  set_sequence_name "group_id_seq"

  has_many :ldap_groups, {
    :class_name => "LdapGroup",
    :foreign_key => "group_id",
    :dependent => :destroy
  }

  has_many :email_parts, {
    :class_name => "EmailPart",
    :foreign_key => "group_id",
    :dependent => :destroy
  }

  belongs_to :profile, {
    :class_name => "Profil",
    :foreign_key => "group_id"
  }
end
