# -*- coding: utf-8 -*-
# license_controller.rb
# Copyright (C) 2007-2012 Opersys inc., All rights reserved.
#
# License slots controller
#
# @author François-Denis Gonthier

class LicensesController < ApplicationController
  layout "standard"

  before_filter :init_menu

  public

  # does not work in initialize
  def init_menu
    @menus.set_selected("teambox")
    @menus.set_selected("licenses")
  end


  def list
    @is_reseller = Reseller.is_reseller?() # main

    # get org id
    @org_id = params[:org_id]

    # do not allow non-resellers to specify org_id
    if ! @is_reseller and ! @org_id.nil?()
      redirect_to :action => "list"
      return
    end

    if @org_id.nil?() # org_id unspecified
      # get "main" organization (assume there is one!)
      org_kdn = Activator.main_org_kdn()
      @org_id = Organization.find(:first, {:conditions => ["name = ?", org_kdn]}).org_id
    end

    # check if org exists
    begin
      @org = Organization.find(@org_id)
    rescue
      flash[:error] = "This organization does not exist."
      redirect_to :action => "list"
      return
    end

    @list_seats = LoginSeats.find(:all, { :conditions => ["org_id = ?", @org_id]})
    begin
      @license = License.from_kdn(Activator.main_org_kdn())
      if not @license
        @no_license = true
      end
    rescue Exception => ex
      @no_license = true
    end

    @total_seats_used = 0
    @orgs = []
    Organization.find(:all).each do |org|
      if org.status == 2
        seats_allocated = 0
        seats_used = LoginSeats.find(:all, {:conditions => ["org_id = ?", org.org_id]}).length
        begin
          seats_allocated = LoginSeatsAllocation.find(org.org_id).num
        rescue
          seats_allocated = "Unlimited"
        end
        @total_seats_used += seats_used
        @orgs += [[org, seats_used, seats_allocated]]
      end
    end
  end

  def free_login_seat
    begin
      seat = LoginSeats.find(params[:username])
      seat.destroy
      seat.save
    rescue
      flash[:error] = "This seat was not found."
    end
    redirect_to :action => "list", :org_id => params[:org_id]
    return
  end

end
