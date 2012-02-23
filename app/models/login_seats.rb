# login_seats.rb
# Copyright (C) 2008-2012 Opersys inc., All rights reserved.
#
# Login seats
#

class LoginSeats < ActiveRecord::Base
  set_table_name 'login_seats'
  set_primary_key 'user_name'
end
