# -*- coding: utf-8 -*-
# activation_controller.rb --- Activation controller.
# Copyright (C) 2006-2012 Opersys inc.  All rights reserved.

# Author: François-Denis Gonthier

require 'activator'
require 'activator_identity'
require 'frame_work'
require 'tbxsosd_configd'

class ActivationController < ApplicationController
  layout "activation"
  skip_before_filter :menus_avail

  before_filter :set_default_act_name
  before_filter :dispatch_act
  before_filter :wizard_nav

  private

  def redirect_to_step0(act_name)
    if ! session[:step0_action].nil?
      redirect_to :action => session[:step0_action], :act_name => act_name
    else
      redirect_to :action => 'step0', :act_name => act_name
    end
  end

  def redirect_to_activated
    redirect_to :action => "list", :controller => "info"
  end

  # get the requested step, or nil for actions that are not related to a step in particular 
  def get_req_step(action)
    begin
      req_step = params[:action].scan(/.*step([0-9]+).*/)[0][0];
    rescue
      return nil
    end
  end

  # default activation name is "main"
  def set_default_act_name
    @act_name = "main"
    if not params["act_name"].nil?
      @act_name = params["act_name"]
    end
  end


  # local dispatcher (overrides app/controllers/applications.rb dispatch method)
  def dispatch_act
    # redirect to dashboard if main activation is done and we're trying to show an activation page for the main activation
    if Activator.has_activated_main? and @act_name == "main"
      redirect_to_activated
      return false
    end

    req_step = get_req_step(params[:action])

    if req_step.nil?
      # action contains no step... 
      if params[:actionl] == "cancel" and not activator_exists
        redirect_to_step0(@act_name)
        return false
      end
    else
      # action contains a step...

      # check if activater is present
      activator_exists = Activator.exists?(@act_name)

      if activator_exists
        # got an activator... check if we're in the right step
        cur_activator = Activator.load_existing(@act_name)

        if req_step.to_i != cur_activator.step.to_i
          redirect_to :action => "step#{cur_activator.step}", :controller => 'activation', :act_name => @act_name
          return false
        end
      else
        # no activator yet... make sure user gets to step0 if not already done
        if req_step.to_i != 0
          redirect_to_step0(@act_name)
          return false
        end
      end
    end
  end

  # Catch cancellation, next and previous buttons for every steps
  def wizard_nav
    activator = nil
    if not @act_name.nil? and Activator.exists?(@act_name)
      activator = Activator.load_existing(@act_name)
    else
      return
    end

    if not params[:cancel_activation].nil?
      redirect_to :action => 'cancel', :act_name => @act_name
      return
    elsif not params[:previous_step].nil?
      activator.previous_step
      activator.save
      
      redirect_to :action => "step#{activator.step}", :act_name => @act_name
      return
    end
  end

  public

  def index
    redirect_to_step0 @act_name
  end

  def cancel
    activator = Activator.load_existing(@act_name)
    if not params[:really_cancel].nil?
      # Cancel activation.
      activator.delete
      redirect_to_step0 @act_name
      return
    elsif not params[:no_cancel].nil?
      # Cancel cancelling
      redirect_to :action => 'step#{activator.step}', :act_name => @act_name
    end
  end
 
  # Welcome message.
  def step0
    session[:step0_action] = params[:action]

    # List the certified identities that can be used to activate other
    #all_activators = Activator.list
    #@activators = all_activators.select do |a|
    #  if not a.activated?
    #    true
    #  end
    #end if not all_activators.nil?
        
    @initial_activation = !Activator.has_activated_main?
  end

  def step0_advanced
    session[:step0_action] = params[:action]

    # Just initialize the activator.
    activator = Activator.load_existing(@act_name)
    activator.save
  end

  # Moves to the first step. 
  def step0_post
    step = nil

    if params[:act_type] == "sub_activation"
      activator = Activator.create_new("main", "main")
      activator.next_step
      activator.save
      step = "step1"
    elsif params[:act_type] == "initial_activation"
      activator = Activator.create_main
      activator.next_step
      activator.save
      step = "step1"
    elsif params[:act_type] == "resume_activation"
      activator = Activator.load_existing(@act_name)
      step = "step#{activator.step}"
    end
  
    redirect_to :action => step, :act_name => activator.name
  end

  def step0_restore
     if check_upload_file("backup_data")
       # Restore the backup.
       begin
         kcd = TbxsosdConfigd.new
         kcd.convert_kps_backup(params[:backup_data])        
         redirect_to_activated
       rescue Exception => ex
         KLOGGER.info(ex.to_s)
         flash[:error] = GTEH_("activation.restore_backup_failed")
         redirect_to_step0 @act_name
       end
     else
       flash[:error] = GTEH_("activation.step0.error.no_data")
       redirect_to_step0 @act_name       
     end
  end

  # Input the base information for the CSR.
  def step1
    if @act_name.nil?
      redirect_to :controller => params[:controller], :action => params[:action], :act_name => "main"
      return
    end

    activator = Activator.load_existing(@act_name)

    # fill inputs (in case of error, we show step1 again))
    params[:act_admin_name] = activator.admin_name
    params[:act_admin_email] = activator.admin_email
    params[:act_country] = activator.country
    params[:act_state] = activator.state
    params[:act_location] = activator.location
    params[:act_org] = activator.org
    params[:act_org_unit] = activator.org_unit
    params[:act_domain] = activator.domain
    params[:act_email] = activator.email

#     if in_dev?  # && ! DEV_ACT_CSR_C.nil?
#       params[:act_country] = DEV_ACT_CSR_C
#       params[:act_state] = DEV_ACT_CSR_ST
#       params[:act_location] = DEV_ACT_CSR_L
#       params[:act_org] = DEV_ACT_CSR_O
#       params[:act_org_unit] = DEV_ACT_CSR_OU
#       params[:act_domain] = DEV_ACT_CSR_CN
#       params[:act_email] = DEV_ACT_CSR_EM
#       params[:act_admin_name] = DEV_ACT_CSR_CCN
#       params[:act_admin_email] = DEV_ACT_CSR_CCEM
#     end
  end

  # Save the provided information.
  def step1_post
    activator = Activator.load_existing(@act_name)

    # Save the data that don't go in the CSR in the Activator.
    activator.admin_name = params[:act_admin_name].strip
    activator.admin_email = params[:act_admin_email].strip

    # Prepare the CSR.
    activator.country = params[:act_country].strip
    activator.state = params[:act_state].strip
    activator.location = params[:act_location].strip
    activator.org = params[:act_org].strip
    activator.org_unit = params[:act_org_unit].strip
    activator.domain = params[:act_domain].strip
    activator.email = params[:act_email].strip

    # validate admin info... csr info is validated in activator* classes
    if activator.admin_name == "" or activator.admin_email == ""
      err = "unknown error"
      if activator.admin_name == ""
        err = "Missing contact name"
      elsif activator.admin_email == ""
        err = "Missing contact email"
      end
      flash[:error] = err
      params[:action] = "step1"
      redirect_to params
      return false
    end

    # If the activator uses a parent's certificate, we move to step4 right away.
    if activator.has_parent?
      activator.step = 4
      activator.save

      redirect_to :action => 'step4', :act_name => @act_name
      return
    end

    # Make the Activator generate the CSR.
    begin
      activator.del_csr # if updating after an error / typo / ...
      junk = activator.get_csr # create it right now (but don't use it) so we know if some parameters are wrong... allow a correction
      activator.next_step
      activator.save
      
      redirect_to :action => 'step2', :act_name => @act_name
    rescue Exception => ex
      KLOGGER.info(ex.to_s)
      flash[:error] = ex
      
      # Move back to step1 on error.
      params[:action] = "step1"
      redirect_to params

      return
    end
  end

  def step2
    
    activator = Activator.load_existing(@act_name)
    @csr = activator.get_csr
  end

  # Simply move to the next step.
  def step2_post
    activator = Activator.load_existing(@act_name)
    activator.next_step
    activator.save

    redirect_to :action => 'step3', :act_name => @act_name
  end

  # The user demands to download the CSR as a file.
  def step2_download_csr
    activator = Activator.load_existing(@act_name)
    send_data activator.get_csr, :type => 'application/x-x509-ca-cert',
                                 :filename => 'teambox_csr.pem'
  end    

  # Make the customer input the signed CSR.
  def step3
    @signed_csr = ""
  end

  # The customer has input the signed CSR, we make a KAR packet for
  # him
  def step3_post
    activator = Activator.load_existing(@act_name)

    # Set the signed CSR and make the KAR, it will be displayed in
    # step3.
    if params[:cert_paste_data] != "" or check_upload_file("cert_file_data")
      if check_upload_file("cert_file_data")
        cert_data = params[:cert_file_data].read
      elsif params[:cert_paste_data] != ""
        cert_data = params[:cert_paste_data]
      end

      # try to normalize input without screwing it
      cert_data = cert_data.gsub(/\r/, "").gsub(/\n+/, "\n").strip 

      begin
        activator.set_cert(cert_data)

        # generate the kar.
        activator.make_kar
        activator.next_step
        activator.save
      rescue ActivatorIdentityCertException => ex
        KLOGGER.info(ex.to_s)
        if ex.is_invalid 
          flash[:error] = GTEH_("activation.step3.error.invalid_cert")
          redirect_to :action => "step3", :act_name => @act_name
          return
        elsif ex.is_incorrect
          flash[:error] = GTEH_("activation.step3.error.cert_does_not_match")
          redirect_to :action => "step3", :act_name => @act_name
          return
        end
          
      rescue Exception => ex
        KLOGGER.info(ex.to_s)
        flash[:error] = GTEH_("activation.step3.error.internal")
      end

      # Next step will show the KAR link.
      redirect_to :action => 'step4', :act_name => @act_name
      return
    else
      flash[:error] = GTEH_("activation.step3.error.no_data")
    end

    redirect_to :action => 'step3', :act_name => @act_name
  end

  def step4
    activator = Activator.load_existing(@act_name)
    @kar = activator.get_kar
    @subject = GTEH_("activation.step4.subject.request_domain_is") % [ activator.domain ]
  end

  def step4_download_kar
    activator = Activator.load_existing(@act_name)
    send_data activator.get_kar, :type => 'text/plain',
                                 :filename => 'kar.bin'
  end

  def step4_post
    activator = Activator.load_existing(@act_name)
    activator.next_step
    activator.save

    redirect_to :action => 'step5', :act_name => @act_name
  end

  def step5
  end
 
  def step5_post
    if check_upload_file("kap_data")
      activator = Activator.load_existing(@act_name)
      begin
        activator.use_kap(params[:kap_data].read)
        activator.next_step
        activator.save
      rescue Exception => ex
        KLOGGER.info(ex.to_s)
        flash[:error] = GTEH_("activation.step5.error.invalid_kap");
        redirect_to :action => 'step5', :act_name => @act_name
        return
      end

      redirect_to :action => 'step6', :act_name => @act_name
    else
      flash[:error] = GTEH_("activation.step5.error.no_data")
      redirect_to :action => 'step5', :act_name => @act_name
    end    
  end
  
  # Done with Activation
  def step6
    # last step is now 7: go to next step so that dispatcher can know when the activation is finished, and not show this page again
    activator = Activator.load_existing(@act_name)
    activator.next_step
    activator.save
  end
end
