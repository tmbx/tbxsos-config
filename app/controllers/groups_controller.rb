# -*- coding: utf-8 -*-
# groups_controller.rb
# Copyright (C) 2007-2012 Opersys inc., All rights reserved.
#
# Group profiles controller
#
# @author François-Denis Gonthier

class GroupsController < ApplicationController
  layout "standard"

  before_filter :check_main_org # in app/controllers/applications.rb
  before_filter :is_reseller
  before_filter :check_auth_mode
  before_filter :init_menu
  before_filter :users_groups_filter   # in app/controllers/profiles.rb
  before_filter :init_misc

  protected

  def is_reseller
    @is_reseller = false
    if Reseller.is_reseller?()
      @is_reseller = true
    end
  end

  def check_auth_mode
    co = ConfigOptions.new
    if ! Auth.ldap_enabled?()
      redirect_to :controller => "info", :action => "list"
      return
    end
  end

  # does not work in initialize
  def init_menu
    @menus.set_selected("ldap")
    @menus.set_selected("divisions")
  end

  def init_misc
    @form_params = {}
    @form_params[:org_id] = @org_id

    @optgroup = "group"

    @fw = FrameWork.new
    init_fields
  end

  def redirect_default
    if ! @org_id.nil?
      redirect_to :action => "list", :org_id => @org_id
    else
      redirect_to :action => "list", :controller => "organizations"
    end
  end

  def init_fields
    @fo = @fw.add_form(@optgroup)

    @fi = @fo.add_field(["group","group_name"], "text", { "autofocus" => true, "required" => true, "size" => 45 })
   
    # changed 2007-12-03 - mail from ragui
    #@fi = @fo.add_field("key_id", "fake", { "force_value" => Key.find(:all)[0].key_id.to_s })
    #@fi = @fo.add_field("key_id", "select", { "required" => true, "input_class" => "input_group_dn_key_id" })
    #@keys = Key.find(:all)
    #@keys.each do |k|
    #  @fi.choices.push({"key" => k.key_id.to_s, "value" => "#{k.key_id.to_s} #{k.owner_name}"})
    #end
    
    fo = @fw.add_form("ldap_group_dn")
    fo.per_field_action = true
    fo.required_notice = false
    fi = fo.add_field("add_group_dn", "text", { "action" => "add", "size" => 55})
    fi = fo.add_field("list_group_dn", "select", { "action" => "remove", "size" => 4, "input_class" => "input_group_dn_list"})
    fi.tags["onChange"] = "ldapGroupDnRenameUpdate();" 
    fi = fo.add_field("group_dn_rename", "text", { "action" => "edit_ldap_group", "size" => 55 })
    fi.disabled = true
  end


  public


  def index
    redirect_default
  end

  def list
    begin
      @group_profiles = Profil.find(:all, { :conditions => ["org_id = ?", @org_id]})
    rescue
      redirect_default
      return
    end
  end


  def new
    @profile = Profil.new
    @profile.group = GroupProfil.new
    @profile.organization = @org
  end

  def create
    @profile = Profil.new
    @profile.group = GroupProfil.new
    @profile.organization = @org

    # validate form inputs
    @fw.form_validate(@optgroup, params)
    if @fw.forms[@optgroup].error
      render :action => "new"
      return
    end

    ## validate key existance
    #if ! Key.find(:all, { :conditions => ["key_id = ?", params[:key_id]]})
    #  flash[:error] = GTEH_("groups.key_not_valid")
    #  render :action => "new"
    #  return
    #end

    @profile.group.group_name = params[:group][:group_name]
    # modified 2007-12-03 - mail from Ragui
    @profile.key_id = @org_key_id   ### @fw.forms[@optgroup].fields["key_id"].value
    #@profile.key_id = params[:key_id]
    @profile.prof_type = 'G'
    @profile.group.status = 'A'

    begin
      @profile.save
      @profile.group.save
    rescue
      flash[:error] = GTEH_("groups.could_not_create")
      render :action => "new"
      return
    end

    begin
      # Once the group profile and root profile are saved, we need to
      # set the user ID in the profile otherwise it just won't be set.
      @profile.group_id = @profile.group.group_id
      @profile.save
    rescue
      flash[:error] = GTEH_("groups.could_not_save")
      redirect_default
      return
    end

    redirect_to :controller => "groups", :action => "edit", :org_id => @org_id, :id => @profile, :anchor => "edit_ldap_groups"
  end



  def edit
    if ! @id.nil?
      @form_params[:id] = @id

      @orgs = Organization.find(:all)

      @form_params[:id] = @id
      @group = @profile.group
      @ldap_groups = @profile.group.ldap_groups

      @fw.forms[@optgroup].fields[["group","group_name"]].value = @profile.group.group_name
      #@fw.forms[@optgroup].fields["key_id"].value = @profile.key_id
      
      @ldap_groups.each do |e|
        @fw.forms["ldap_group_dn"].fields["list_group_dn"].choices.push({"key" => e.ldap_group_id, "value" => e.group_dn})
      end
      return
    end

    redirect_default
  end



  def update
    if ! @id.nil?
      @form_params[:id] = @id

      @orgs = Organization.find(:all)

      @group = @profile.group
      @ldap_groups = @profile.group.ldap_groups

      @fw.forms[@optgroup].fields[["group","group_name"]].value = @profile.group.group_name
      #@fw.forms[@optgroup].fields["key_id"].value = @profile.key_id
 
      @ldap_groups.each do |e|
        @fw.forms["ldap_group_dn"].fields["list_group_dn"].choices.push({"key" => e.ldap_group_id, "value" => e.group_dn})
      end
    
      # validate form inputs
      @fw.form_validate(@optgroup, params)
      if @fw.forms[@optgroup].error
        render :action => "edit"
        return
      end

      @profile.group.group_name = params[:group][:group_name]


      #key_id = @fw.forms[@optgroup].fields["key_id"].value
      ## validate if key is valid
      #if ! Key.find(:all, { :conditions => ["key_id = ?", key_id]})
      #  render :action => "edit", :id => @id
      #  return
      #end
      # modified 2007-12-03 - mail from Ragui
      #@profile.key = Key.find(key_id)
      #@profile.key = Key.find(params[:key_id])

      begin
        @profile.group.save
        @profile.save      
      rescue
        flash[:error] = GTEH_("groups.failed_to_update_profile")
        redirect_default
        return
      end

      flash[:notice] = GTEH_("groups.update_successful")
      redirect_default
      return
    end

    redirect_default
  end


  # Add or remove email parts in the profile.
  def update_ldap_groups
    if ! params[:add].nil?
      @ldap_group = LdapGroup.new

      if ! params[:add_group_dn].nil? && params[:add_group_dn] != "" 
        begin
          @ldap_group.group_dn = params[:add_group_dn]
          @ldap_group.group = @profile.group

          # Save the new email part.
          @ldap_group.save
        rescue Exception => ex
          if /.*PGError.*dup.*/.match(ex.to_s)
            flash[:error] = GTEH_("groups.group_dn_duplicate_key")
          else
            flash[:error] = GTEH_("groups.failed_to_insert_group_dn")
          end
        end
      end
    elsif ! params[:edit_ldap_group].nil?

      if ! params[:list_group_dn].nil? && ! params[:group_dn_rename].nil?
        if params[:group_dn_rename].length > 0
          @part = LdapGroup.find(params[:list_group_dn])
          @part.group_dn = params[:group_dn_rename]
  
          if ! @part.nil?
            begin
              @part.save
            rescue
              flash[:error] = GTEH_("groups.failed_to_rename_group_dn")
            end
          end
        end
      end
    elsif ! params[:remove].nil?

      if ! params[:list_group_dn].nil?
        @part = LdapGroup.find(params[:list_group_dn])

        if ! @part.nil?
          begin
            @part.destroy
          rescue
            flash[:error] = GTEH_("groups.failed_to_remove_group_dn")
          end
        end
      end
    end

    redirect_to :action => "edit", :id => @profile
  end


  def delete
    if ! @id.nil?
      begin
        @profile.group.destroy
        @profile.destroy

        flash[:notice] = GTEH_("groups.deleted_successfully")

      rescue
        flash[:error] = GTEH_("groups.failed_to_remove_group")
      end
    end

    redirect_default
  end
end


