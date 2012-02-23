# -*- coding: utf-8 -*-
# organization.rb
# Copyright (C) 2007-2012 Opersys inc., All rights reserved.
#
# Organization model
#
# @author François-Denis Gonthier

class Organization < ActiveRecord::Base
  set_table_name "organization"
  set_primary_key "org_id"
  set_sequence_name "org_id_seq"

  has_many :profiles, :class_name => "Organization", :foreign_key => "org_id"
end
