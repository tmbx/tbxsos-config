# login_seats_allocation.rb
# Copyright (C) 2008-2012 Opersys inc., All rights reserved.
#
# Login seats allocation
#

class LoginSeatsAllocation < ActiveRecord::Base
  set_table_name 'login_seats_allocation'
  set_primary_key 'org_id'
end
