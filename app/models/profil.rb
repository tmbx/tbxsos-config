# -*- coding: utf-8 -*-
# profil.rb
# Copyright (C) 2007-2012 Opersys inc., All rights reserved.
#
# Profile model
#
# @author François-Denis Gonthier

class Profil < ActiveRecord::Base
  set_table_name "profiles"
  set_primary_key "prof_id"
  set_sequence_name "prof_id_seq"

  has_one :login, {
    :class_name => "Login",
    :foreign_key => "prof_id",
    :dependent => :destroy
  }

  # Profiles are linked to an User profile or to a Group profile.

  has_one :user, {
    :class_name => "UserProfil",
    :foreign_key => "prof_id",
  }

  has_one :group, {
    :class_name => "GroupProfil",
    :foreign_key => "prof_id",
  }

  belongs_to :organization, {
    :class_name => "Organization",
    :foreign_key => "org_id"
  }

  belongs_to :key, {
    :class_name => "Key",
    :foreign_key => "key_id"
  }

  # yeah.. keys are in profiles, but currently, they are bound to organizations (one key per org)
  def self.find_org_keys(org_id)
    find_by_sql ["select DISTINCT key_id, org_id from profiles where org_id=? and key_id IS NOT NULL", org_id]
  end
end
