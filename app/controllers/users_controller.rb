# -*- coding: utf-8 -*-
# users_controller.rb
# Copyright (C) 2007-2012 Opersys inc., All rights reserved.
#
# Profile management controller.
#
# @author François-Denis Gonthier

class UsersController < ApplicationController
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
    if Auth.ldap_enabled?()
      redirect_to :controller => "info", :action => "list"
      return
    end
  end

  # does not work in initialize
  def init_menu
    @menus.set_selected("userman")
  end

  def init_misc
    @form_params = {}
    @form_params[:org_id] = @org_id

    @optgroup = "user" # by default

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
    ### USERS MANAGEMENT ###
    @fo = @fw.add_form("user")

    @fi = @fo.add_field(["user", "created_on"], "text",
                        { "disabled" => "true",
                          "size" => 35 })
    @fi = @fo.add_field(["user", "full_name"], "text",
                        { "autofocus" => true,
                          "required" => true,
                          "size" => 35 })
    @fi = @fo.add_field(["pemail", "email_address"], "text",
                        { "required" => true,
                          "realtype" => "email",
                          "size" => 35 })
    @fi = @fo.add_field(["login", "user_name"], "text",
                        { "required" => true,
                          "size" => 35 })

    # for invisible passwords
    @fi = @fo.add_field(["login", "passwd"], "password",
                        { "required" => true,
                          "size" => 35 })
    @fi = @fo.add_field(["login", "passwd_verif"], "password",
                        { "required" => true,
                          "size" => 35 })
    @fi.verification_field = ["login", "passwd"]

    @fi = @fo.add_field(["note", "note"], "textarea",
                        { "rows" => 6,
                          "cols" => 35 })

    fo = @fw.add_form("sec_emails")
    fo.per_field_action = true
    fo.required_notice = false

    fi = fo.add_field("add_sec_email", "text",
                      { "action" => "add",
                        "size" => 54 })
    fi = fo.add_field("list_sec_email", "select", {
                        "action" => "remove",
                        "size" => 4,
                        "input_class" => "input_sec_email_list" })

    fi.tags["onChange"] = "userSecEmailRenameUpdate();"

    fi = fo.add_field("sec_email_rename", "text", 
                      { "action" => "edit_sec_email",
                        "size" => 54 })
    fi.disabled = true
  end


  # name sucks because it also checks againts the current login (it's ok if it's the same login and we're editing it)
  def user_exists?(params, current_login=nil)
    # checks user existence
    begin
      tmp_login = Login.find(params[:login][:user_name])
      # new: not nil
      # edit: not nil
      if current_login.nil? # creating a new login
        if ! tmp_login.user_name.nil?
          # this login exists
         return true
        end
      else # editing an existing login
         if ! tmp_login.user_name.nil? && tmp_login.user_name != current_login
         return true
        end
      end
    rescue
      # do nothing
    end

    return false
  end


  def update_logins
    # profile is already initialized in before_filter

    @login = @profile.login

    Login.transaction do
      if ! @login.nil?
        ### update
        if @profile.login.user_name != params["login"]["user_name"]
          @login.destroy              

          @login = Login.new
          @login.org_id = @org_id
          @login.prof_id = @id
          @login.id = params[:login][:user_name]
          @login.passwd = params[:login][:passwd]
          @login.status = 'A'
  
          @login.save

          return true
        else
          @login.update_attributes(:passwd => params[:login][:passwd])
          @login.save

          return true
        end
      else
        @login = Login.new
        @login.org_id = @org_id
        @login.prof_id = @id
        @login.id = params[:login][:user_name]
        @login.passwd = params[:login][:passwd]
        @login.status = 'A'

        @login.save
        return true
      end
    end

    return false
  end


  public


  def index
    redirect_default
  end

  # List of profiles.
  def list
    begin
      @profiles = Profil.find(:all, { 
                                :conditions => ["org_id = ?", @org_id],
                              }).sort_by { |x| x.user.first_name };

      # Prepare the list of anchors to create.
      @anchors = []
      @profiles.each do |up|
        @anchors << up.user.first_name[0..0]
      end
      @anchors.uniq!
    rescue
      redirect_default
      return
    end
  end

  # New profile.
  def new
  end

  # Creates a new profile.
  def create
    @profile = Profil.new
    @profile.user = UserProfil.new
    @profile.user.primary_email = Email.new
    @profile.organization = @org
    @profile.key_id = @org_key_id     ### @fw.forms[@optgroup].fields["key_id"].value

    # validate form inputs
    @fw.form_validate(@optgroup, params)
    if @fw.forms[@optgroup].error
      render :action => "new"
      return
    end
    if user_exists?(params)
      @fw.forms[@optgroup].fields[["login", "user_name"]].errors.push("This login already exists.")
      render :action => "new"
      return
    end
    # validate key existance
    #if ! Key.find(:all, { :conditions => ["key_id = ?", params["key_id]]})
    #  flash[:error] = "This key is not valid."
    #  render :action => "new"
    #  return
    #end

    @profile.prof_type = 'U'
    @profile.user.status = 'A'

    # workaround 
    @profile.user.first_name = get_first_name(params[:user][:full_name])
    @profile.user.last_name = get_last_name(params[:user][:full_name])
    #@profile.user.first_name = params[:user][:first_name]
    #@profile.user.last_name = params[:user][:last_name]
    @profile.user.primary_email.status = 'A'
    @profile.user.primary_email.is_primary = true
    @profile.user.primary_email.email_address = params[:pemail][:email_address]

    begin
      Profil.transaction do
        @profile.save
        # Once the user profile and root profile are saved, we need to
        # set the user ID in the profile otherwise it just won't be set.
        @profile.user_id = @profile.user.user_id

        @profile.save

        @id = @profile.id
        if update_logins == true
          flash[:notice] = GTEH_("users.user_created_successfully") 
        else
          flash[:notice] = GTEH_("users.user_created_successfully_but_could_not_save_login")
        end
      end
    rescue
      log_error $!
      flash[:error] = GTEH_("users.create_user_failed")
    end

    redirect_default
  end

  # Edit a profile.
  def edit
    if ! @id.nil?
      @form_params[:id] = @id

      @user = @profile.user
      @pemail = @profile.user.primary_email
      @semails = @profile.user.secondary_emails
      @login = @profile.login
      @semails.each do |e|
        @fw.forms["sec_emails"].fields["list_sec_email"].choices.push({"key" => e.id, 
                                                                        "value" => e.email_address})
      end

      # workaround
      names = [ @user.first_name,  @user.last_name ]
      @fw.forms[@optgroup].fields[["user", "created_on"]].value = @profile.created_on.strftime('%Y-%m-%d')
      @fw.forms[@optgroup].fields[["user", "full_name"]].value = names.join(" ")
      @fw.forms[@optgroup].fields[["pemail", "email_address"]].value = @pemail.email_address
      @fw.forms[@optgroup].fields[["note", "note"]].value = @profile.note
      
      if ! @profile.login.nil?
        @fw.forms[@optgroup].fields[["login","user_name"]].value = @profile.login.user_name
        @fw.forms[@optgroup].fields[["login","passwd"]].value = @profile.login.passwd
        @fw.forms[@optgroup].fields[["login","passwd_verif"]].value = @profile.login.passwd
      end

      return
    end

    redirect_default
  end


  def update
    if ! @id.nil?
      @form_params[:id] = @id

      #@orgs = Organization.find(:all)
 
      @user = @profile.user
      @pemail = @profile.user.primary_email
      @semails = @profile.user.secondary_emails
      @login = @profile.login
      @semails.each do |e|
        @fw.forms["sec_emails"].fields["list_sec_email"].choices.push({ "key" => e.id, 
                                                                        "value" => e.email_address })
      end

      # workaround
      names = [ @user.first_name,  @user.last_name ]
      @fw.forms[@optgroup].fields[["user", "full_name"]].value = names.join(" ")
      @fw.forms[@optgroup].fields[["pemail", "email_address"]].value = @pemail.email_address
      if ! @profile.login.nil?
        @fw.forms[@optgroup].fields[["login","user_name"]].value = @profile.login.user_name
        @fw.forms[@optgroup].fields[["login","passwd"]].value = @profile.login.passwd
        @fw.forms[@optgroup].fields[["login","passwd_verif"]].value = @profile.login.passwd
      end

      # validate form inputs
      @fw.form_validate(@optgroup, params)
      if @fw.forms[@optgroup].error
        render :action => "edit", :id => @id
        return
      end
      if user_exists?(params, @login.user_name)
        @fw.forms[@optgroup].fields[["login", "user_name"]].errors.push("This login already exists.")
        render :action => "edit", :id => params[:id]
        return
      end

      begin
        Profil.transaction do
          @profile.update_attribute("org_id", @org_id)
          # workaround
          @profile.user.user_id = @profile.user_id
          @profile.user.first_name = get_first_name(params[:user][:full_name])
          @profile.user.last_name = get_last_name(params[:user][:full_name])
          @profile.user.primary_email.update_attributes(params[:pemail])
          @profile.note = params[:note][:note]

          @profile.user.save
          @profile.save

          if update_logins == true
            flash[:notice] = GTEH_("users.user_saved_successfully")
          else
            flash[:notice] = GTEH_("users.user_saved_successfully_but_could_not_save_login")
          end
        end
      rescue
        log_error $!
        flash[:error] = GTEH_("users.update_user_failed")
      end
    end

    redirect_default
  end

  def delete
    begin
      Profil.transaction do
        @profile.user.primary_email.destroy
        @profile.user.destroy
        @profile.destroy
      end

      flash[:notice] = GTEH_("users.user_deleted_successfully")
    rescue
      flash[:error] = GTEH_("users.delete_user_failed")
    end

    redirect_default
  end


  # Add a secondary email address to an user.
  def update_emails
    if ! params[:add].nil?
      @email = Email.new

      if ! params[:add_sec_email].nil? &&  params[:add_sec_email] != ""
        @email.email_address = params[:add_sec_email]

        # Set a few parameter we don't yet care about.
        @email.user_id = @profile.user.id
        @email.status = 'A'
        @email.is_primary = 'f'

        # Save the new address.
        begin
          @email.save
          flash[:notice] = GTEH_("users.sec_email_add_success")
        rescue
          flash[:error] = GTEH_("users.sec_email_add_failed")
        end
      end
    elsif ! params[:edit_sec_email].nil?

      if ! params[:list_sec_email].nil? && ! params[:sec_email_rename].nil?
        if params[:sec_email_rename].length > 0
          @part = Email.find(params[:list_sec_email])
          @part.email_address = params[:sec_email_rename]

          if ! @part.nil?
            begin
              @part.save
            rescue
              flash[:error] = GTEH_("users.sec_email_rename_failed")
            end
          end
        end
      end
    elsif ! params[:remove].nil?
      if ! params[:list_sec_email].nil?
        @email = Email.find(params[:list_sec_email])
        
        if ! @email.nil?
          begin
            @email.destroy
            flash[:notice] = GTEH_("users.sec_email_remove_success")
          rescue
            flash[:error] = GTEH_("users.sec_email_remove_failed")
          end
        end
      end
    end

    redirect_to :action => "edit", :id => @profile
  end
end

