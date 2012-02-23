# -*- coding: utf-8 -*-
# application.rb --- Application base controller.
# Copyright (C) 2006-2012 Opersys inc.  All rights reserved.

# Author: François-Denis Gonthier

require 'activator'
require 'safeexec'
require "menus"
require 'bundle'
#require "htmlentities" # needs gem install htmlentities
  # strings are not converted right now so there could be bugs

# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  before_filter :reset_error
  before_filter :change_language
  before_filter :prepare_menus
  before_filter :req_cache_init
  before_filter :login_done
  before_filter :dispatch
  before_filter :init_strings

  protected

  def reset_error
    session[:exception_msg] = nil
    session[:exception_bck] = nil
    session[:sysinfo] = nil
  end

  Activator.basedir = TEAMBOX_ACT_DIR
  Bundle.archive_dir = File.join(TEAMBOX_ACT_DIR, "archive_bundle")
  Activator.teambox_ssl_cert_path = TEAMBOX_SSL_CERT
  Activator.teambox_sig_pkey_path = ACT_SIG_PKEY_PATH
  Activator.initialize_static

  def change_language
    if ! params[:clang].nil?
      if params[:clang] == 'en' || params[:clang] == 'fr'
        session[:lang] = params[:clang]
        gettext_change_language(params[:clang])
      end
    elsif ! session[:clang].nil?
      gettext_change_language(session[:clang])
    else
      # already done in config/environment.rb
      ## gettext_change_language('en')
    end
  end

  def req_cache_init
    #ReqCache.init(true)
  end

  # check if user is loggued... if not, redirect to index
  def login_done
    if not session[:ok]
      redirect_to :action => 'index', :controller => 'index'
      return false
    end
  end

  # global dispatcher
  def dispatch
    # redirect to activation-step0 if main activation is not done and
    # we're trying to show a non-activation page
    spoof_act = File.exists?(File.join(TEAMBOX_ACT_DIR, "activated"))
    main_act = Activator.has_activated_main?
    not_in_act = params[:controller] != "activation"  

    if not spoof_act and not main_act and not_in_act
      redirect_to :action => "step0", :controller => 'activation'
      return false
    end
  end

  def prepare_menus
    @menus = Menus.new # /lib/menus.rb

    if Auth.ldap_enabled?()
      @menus.set_disabled("userman")
    else
      @menus.set_disabled("ldap")
    end
  end

  def init_strings
    @page_title = GTEH_("#{params[:controller]}.page_title")
    @page_doc = GTEH_("#{params[:controller]}.page_doc")

    content_type = headers["Content-Type"] || 'text/html'
    if /^text\//.match(content_type)
      headers["Content-Type"] = "#{content_type}; charset=iso-8859-15" 
    end
 end

  def rescue_action(exception)
    if ERROR_HANDLE
      log_error(exception) if logger
      erase_results if performed?

      # Let the exception alter the response if it wants.
      # For example, MethodNotAllowed sets the Allow header.
      if exception.respond_to?(:handle_response!)
        exception.handle_response!(response)
      end

      begin
        sysinfo = KPopen3.new(ERROR_INFO_FILE)
        sin, sout, serr = sysinfo.pipes
        sin.close

        ret = SafeExec.empty_pipes([sout, serr])
        sysinfo.close

        @sysinfo = ret[0]
      rescue
        # We must not let errors go through here otherwise.
        @sysinfo = "Error collecting system information."
      end

      if exception         
        @exception_msg = "Exception: #{exception.message}"
        @exception_bck = exception.backtrace.join("\n")
      else
        @exception_msg = "Exception: unknown"
        @exception_bck = ""
      end

      render :template => 'errors/error.rhtml', :layout => 'error'
    else
      super
    end
  end

  # work around & does not belong here
  def get_first_name(string)
    return string.split(" ")[0]
  end
  def get_last_name(string)
    return string.split(" ")[1..9999].join(" ")
  end

  # used for some controllers (right now: organizations, groups and users)
  # find the main org
  # if no org present, redirect to organizations management
  def check_main_org
    begin
      @main_org_kdn = Activator.main_org_kdn()
      @main_org = Organization.find(:first, {:conditions => ["name = ?", @main_org_kdn]})
      @main_org_id = @main_org.org_id
    rescue
      # should not happen... can't access this controller without prior activation
      flash[:error] = "Internal error: there are no organizations in the TBXSOS."
      render :template => 'errors/internal_error'
      return false
    end
  end

  # used for some controllers (right now: groups and users)
  # tried to create a new class.. didn't work, didn't try to make it work
  # check several things in a mixed way... could improve readability some day
  # init data here too so we avoid repetitions in the action controllers
  # basically:
  # - if org specified, check validity or redirect
  # - if not a reseller, choose first org found or redirect
  # - if profile specified, check validity or redirect
  # - if specified or found, set org_id, org, profile_id, profile
  # so, those variables are fully valid if they reach actions definitions
  def users_groups_filter
    @org_id = nil
    @org = nil
    @id = nil
    @profile = nil

    # profile id specified? (update, delete)
    tmp_id = params[:id]
    if ! tmp_id.nil?
      # specified a profile id
      begin
        tmp_profile = Profil.find(tmp_id)
      rescue
        #
      end
      if ! tmp_profile.nil?
        # profile found
        @id = tmp_id
        @profile = tmp_profile
        @org_id = @profile.org_id
        @org = Organization.find(@org_id)
      else
        # profile not found
        redirect_default
        return false
      end
    end

    # no org set yet... org id is specified
    tmp_org_id = params[:org_id]
    if @org_id.nil? && ! tmp_org_id.nil?
      begin
        # find org
        tmp_org = Organization.find(tmp_org_id)
      rescue
        #
      end
      if ! tmp_org.nil?
        # org found
        @org_id = tmp_org_id
        @org = tmp_org
      else
        # organization not found
        redirect_default
        return false
      end
    end

    if @org_id.nil?
      # use main org as default
      @org_id = @main_org_id
      @org = @main_org
    end

    # get key associated to org
    tmp_key_id = Org.get_first_key_id(@org_id)
    if not tmp_key_id.nil?
      @org_key_id = tmp_key_id
    end

  end

end
