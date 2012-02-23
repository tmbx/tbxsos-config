# -*- coding: utf-8 -*-
# profiles_controller.rb
# Copyright (C) 2007-2012 Opersys inc., All rights reserved.
#
# KPS updates controller.
#
# @author François-Denis Gonthier

require 'socket'
require 'tbxsosd_configd'


class UpdatesController < OptionsController
  layout "standard"

  before_filter :init_forms

  before_filter :init_menu
  def init_menu
    @menus.set_selected("updates")
  end

  before_filter :set_optgroup
  def set_optgroup
    @optgroup = "update_options"
  end

  # language could not be set yet in ititialize so we use a filter
  def init_forms
    super

    ### UPDATE NOW ###
    fo = @fw.add_form("update_now")
    fo.required_notice = false
    fo.per_field_action = true
    fi = fo.add_field("update_file", "file", { "action" => "update", "size" => 30 })
  end

  private

  def sanitize_filename(file_name)
    f = File.basename(file_name)
    f.sub(/[^\w\.\-]/,'_')
  end

  public

  def update

    @success = 0
    @nofile = 0


    if not check_upload_file("update_file")
      @nofile = 1
    else
      begin
        fn = "/tmp/" + sanitize_filename(params[:update_file].original_filename)

        cfgd = TbxsosdConfigd.new

        # Save the file.
        File.open(fn, "w") do |fo|
          fo.write(params[:update_file].read)
        end

        if cfgd.install_bundle(fn)
          flash[:notice] = GTEH_("updates.update_now.successful")
        else
          flash[:error] =  GTEH_("updates.update_now.failed")
        end
      rescue NoDaemon => ex
        flash[:error] = GTEH_("updates.update_now.internal_problem")
      end

      redirect_to :action => 'list'
    end
  end
end
