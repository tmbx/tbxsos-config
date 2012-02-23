# -*- coding: utf-8 -*-
# User_Profil.rb
# Copyright (C) 2007-2012 Opersys inc., All rights reserved.
#
# User Profile model
#
# @author François-Denis Gonthier

class UserProfil < ActiveRecord::Base
  set_table_name "user_profiles"
  set_primary_key "user_id"

  has_many :email, :class_name => "Email", :foreign_key => "Emails"

  has_one :primary_email, {
    :class_name => "Email",
    :foreign_key => "user_id",
    :conditions => "is_primary = 't'",
    :dependent => :destroy
  }

  has_many :secondary_emails, {
    :class_name => "Email",
    :foreign_key => "user_id",
    :conditions => "is_primary = 'f'",
    :dependent => :destroy
  }

  belongs_to :profile, :class_name => "Profil", :foreign_key => "prof_id"
end
