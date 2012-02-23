# -*- coding: utf-8 -*-
# profiles_controller.rb
# Copyright (C) 2007-2012 Opersys inc., All rights reserved.
#
# Organization management controller.
#
# @author François-Denis Gonthier


class OrganizationsController < ApplicationController
  layout "standard"

  before_filter :init_menu

  # does not work in initialize
  def init_menu
    @menus.set_selected("organization")
  end

  before_filter :check_main_org # in app/controllers/applications.rb
  before_filter :is_reseller
  before_filter :check_org
  before_filter :init_misc

  protected

  def is_reseller
    @is_reseller = false
    if Reseller.is_reseller?()
      @is_reseller = true
    end
  end

  def check_org
    # for debugging only... we don't want to create or delete an organisation in production
    @can_create_orgs = false
    @can_edit_orgs = false
    @can_delete_orgs = false

    @org_id = @main_org_id
    @org = @main_org

    # id specified
    tmp_id = params[:id]
    if ! tmp_id.nil?
      begin
        @org_id = tmp_id
        @org = Organization.find(@org_id)
      rescue
        # org specified but not found
        redirect_default
      end
    end
  end

  def init_misc
    @form_params = {}
    @optgroup = "organization"
    @form_params[:optgroup] = @optgroup

    @fw = FrameWork.new
    init_fields
  end

  def redirect_default
    redirect_to :action => "list"
  end

  # language could not be set yet in ititialize so we use a filter
  def init_fields
    @fo = @fw.add_form("organization")
    @fi = @fo.add_field(["org","name"], "text", { "autofocus" => true })
    @fi.readonly = true
    @fi = @fo.add_field(["org","forward_to"], "text")
  end

  public

  def index
    redirect_default
  end

  def list
    @has_ldap = Auth.ldap_enabled?()
    @orgs = Organization.find(:all, { 
                                :conditions => "status = #{Org.status_activated}",
                                :order => "name"
                              })
    # make organization keys available
    # find
    @orgs_keys = {}
    @orgs.each do |org|
      @orgs_keys[org.org_id] = []
      Profil.find_org_keys(org.org_id).each do |prof|
        @orgs_keys[org.org_id] += [prof.key_id]
      end
      # If there is no profile having that key, try to see if there is
      # an activated organization by which we can find the key.
      if @orgs_keys[org.org_id].empty?
        act = Activator.load_org(org.org_id)
        if act and act.keys and act.keys.get_keyid()
          @orgs_keys[org.org_id] += [act.keys.get_keyid()]
        end
      end
    end
    @options = ConfigOptions.new
    @show_groups = Auth.ldap_enabled?()
    @show_users = ! Auth.ldap_enabled?()

    # Get the name of everybody in the organization
    @user_profiles = []
    @group_profiles = []
    @anchors = []
    @licenses = []

    @orgs.each do |o|
      # Interpret information from the organization's license.
      @licenses[o.org_id] = {}
      lic = License.from_kdn(o.name)
      bb = lic.best_before
      @licenses[o.org_id][:best_before] = bb.strftime("%Y-%m-%d")
      @licenses[o.org_id][:best_before_warn] = (Time.new <=> (bb - (15 * 86400))) > 0
      @licenses[o.org_id][:best_before_error] = (Time.new <=> bb) > 0

      if @show_users
        @user_profiles[o.org_id] =
          Profil.find(:all,
                      { 
                        :conditions => "org_id = #{o.org_id} and user_id is not null" 
                      }).sort_by { |x| x.user.first_name }

        # Prepare the list of anchors to create.
        @anchors[o.org_id] = []
        @user_profiles[o.org_id].each do |up|
          @anchors[o.org_id] << up.user.first_name[0..0]
        end
        @anchors[o.org_id].uniq!
      end
      if @show_groups
        @group_profiles[o.org_id] =
          Profil.find(:all,
                      { 
                        :conditions => "org_id = #{o.org_id} and group_id is not null" 
                      }).sort_by { |x| x.group.group_name }
        # Prepare the list of anchors to create.
        @anchors[o.org_id] = []
        @group_profiles[o.org_id].each do |gp|
          @anchors[o.org_id] << gp.group.group_name[0..0]
        end
        @anchors[o.org_id].uniq!        
      end
    end
  end

  # prints the form
  def edit
    @form_params[:id] = @org_id

    @fw.forms["organization"].fields[["org","name"]].value = @org.name
    @fw.forms["organization"].fields[["org","forward_to"]].value = @org.forward_to
  end

  # updates the organization
  def update
    @form_params[:id] = @org_id

    @fw.form_validate("organization", params)

    if @fw.forms["organization"].error
      # resends the form
      render :action => "edit", :id => @org_id
      return
    else
      # update and save
      # @org.update_attribute("name", params[:org][:name])
      @org.update_attribute("forward_to", params[:org][:forward_to])
      begin
        @org.save
        flash[:notice] = GTEH_("organizations.update.ok")
        redirect_default
        return
      rescue
        flash[:error] = GTEH_("organizations.could_not_update_org")
        redirect_default
        return
      end
    end

    redirect_default
  end

  def upload_kap
    if @org_id.nil?
      redirect_to :action => "list"
      return
    end

    if ! check_upload_file("kap")
      KLOGGER.info("File is invalid.")
      flash[:error] = "File is invalid."
      redirect_default
      return
    end

    begin
      activator = Activator.load_org(@org.org_id)
      raise if activator.nil?
    rescue Exception => ex
      err = GTEH_("organization.upload_kap.not_activated_yet")
      KLOGGER.info(err)
      flash[:error] = err
      redirect_default
      return
    end

    begin
      activator.use_kap(kap_str=params[:kap].read(), install_bundle=false, kaptype="other")
      activator.save()
      flash[:notice] = GTEH_("organization.upload_kap.successful")
    rescue Exception => ex
      KLOGGER.info(GTEH_("organization.upload_kap.failed"))
      flash[:error] = GTEH_("organization.upload_kap.failed")
    end

    redirect_default
  end

end

