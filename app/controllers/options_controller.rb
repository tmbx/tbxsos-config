# -*- coding: utf-8 -*-
# options_controller.rb
# Copyright (C) 2007-2012 Opersys inc., All rights reserved.
#
# Options controller.
#
# @author François-Denis Gonthier


require 'tbxsosd_configd'

# this is the parent class for real controllers
# grep -r "< OptionsController" app/controllers/*
class OptionsController < ApplicationController
  layout "standard"

  # it seems like parents before_filters are run before childs before_filters
  before_filter :init_menu # defined in child parents only
  before_filter :init_forms # can be defined in parent and/or child class
  before_filter :adapt_forms # can be defined in parent and/or child class
  before_filter :set_optgroup # defined in child parents only 


  private

  # language could not be set yet in ititialize so we use a filter
  def init_forms
    if ! @fw.nil?
      # was already called in child class - do not re-init forms
      return
    end

    @form_params = {}

    @fw = FrameWork.new

    @co = ConfigOptions.new
    @fw = @co.get_fw_forms_specs(@fw)
  end

  def adapt_forms
    #render :text => "controller: " + params[:controller] + "<br /> forms: " + @fw.forms.keys.join(" "); return false
    cont = params[:controller];
    act = params[:action];
    if cont == "ldap_config" && act == "set"
      optgroup = "ldap_options"
      form = @fw.forms[optgroup]

	  # enable/disable fields based on input from user
      if ! params[:ldap_domain_search].nil? # ldap domain search is checked
        form.fields["ldap_host"].disabled = true # disable ldap host field
	  
      # needed - 2007-12-20
      #else
        #	form.fields["ldap_domain"].disabled = true # disable ldap domain field
      end
    end
  end

  def redirect_default
    if ! @optgroup.nil?
      redirect_to :action => "list"
    else
      redirect_to :action => "index", :controller => "index"
    end
  end

  def index
    redirect_default
  end


  public

  def list
    if @optgroup.nil?
      redirect_default
      return
    end

    @fw = @co.set_field_values_from_options(@fw, @optgroup)

    @options = ConfigOptions.new
  end

  def set
    @form_params[:optgroup] = @optgroup

    # read values from config options, set them as default for field values
    @fw = @co.set_field_values_from_options(@fw, @optgroup)

    # validate form input
    @fw.form_validate(@optgroup, params)

    # redirect if error
    if @fw.forms[@optgroup].error
      render :action => "list", :optgroup => @optgroup
      return
    else

      # no errors, try to save
      begin
        # save form to config options
        @co.save_config_from_form(@fw, @optgroup)

        begin
          kcd = TbxsosdConfigd.new
          if kcd.restart
            flash[:notice] = GTEH_("options.saved_successfully")
          else
            flash[:error] = GTEH_("options.saved_but_server_did_not_restart")
          end
          rescue NoDaemon => ex
          flash[:error] = GTEH_("options.saved_but_server_not_running")
        end

        begin
          if ! @fw.forms[@optgroup].redirect_to.nil?
            redirect_to @fw.forms[@optgroup].redirect_to
            return
          end
        rescue
          render :text => GTEH_("options.failed_to_redirect")
          return
        end

      rescue Exception => ex
        flash[:error] = GTEH_("options.failed_to_save_options")
		raise ex #flash[:error] = ex.to_s
        render :action => "list", :optgroup => @optgroup
        return
      end
    end

    redirect_default
  end
end



