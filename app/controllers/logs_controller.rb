# -*- coding: utf-8 -*-
# login_controller.rb
# Copyright (C) 2007-2012 Opersys inc., All rights reserved.
#
# Log controller
#
# @author François-Denis Gonthier

require 'tempfile'
require 'zlib'

class LogsController < ApplicationController
  layout "standard"

  before_filter :init_menu

  private

  # does not work in initialize
  def init_menu
    @menus.set_selected("logs")
  end

  # Really remove passwords from applications some day
  def hide_passwords(str)
    newlog = []

    str.split("\n").each do |line|
      if line =~ /(pw|pass|passwd|password)/
        #line = "line with some password in it... hidding."
        #line = line.gsub(/(.*[\s:=_'"]+(pw|pass|passwd|password)[\s:=_'"]+[^\s'"]*[\s:=_'"]+)[^\s'"]*(.*)/i,
        #                  "\\1***HIDDEN***\\3")
        #line = line.gsub(/(.*[\s:=_'"]+(pw|pass|passwd|password)[\s:=_'"]+)[^\s'"]*(.*)/i,
        #                  "\\1***HIDDEN***\\3")
        line = line.gsub(/(.*(password|passwd|pass|pw).?).*/i, "\\1***HIDDEN***")
      end

      newlog = newlog + [ line ]
    end

    return newlog.join("\n")
  end

  # Add 'colors' to the logs.
  def parse_log_lines(lines)
    lines.map do |line|
      if line =~ /\*err\*|\*crit\*/
        [:error, line.gsub(/\*err\*|\*crit\*/, "") ]
      elsif line =~ /\*warning\*/
        [:warning, line.gsub("*warning*", "")]
      else
        [:normal, line.gsub(/\*\w*\*/, "")]
      end
    end    
  end

  public

  # Send the 100 lines of things that have happened the most recently.
  def list
    @active_log = "tbxsosd.log"
    if not params[:active_log].nil?
      @active_log = params[:active_log]
    end
    @logs = Dir["/var/log/teambox/*"].select do |f| 
      !File.directory?(f)
    end.map do |f|
      File.basename(f) 
    end.sort.reverse

    if not params[:zip].nil?
      logs = Dir["/var/log/teambox/*"].map do |f|
        if not File.stat(f).file?
          nil
        else
          f
        end
      end
      
      Tempfile.open("logs") do |tf|
        dir = File.join(Dir.tmpdir, "logs")
        FileUtils.mkdir_p(dir)

        begin
          logs.each do |f|
            # Hide the passwords in each log file.
            bf = File.join(dir, File.basename(f))
            if f !~ /gz$/
              File.open(f, "r") do |f_in|
                File.open(bf, "w") do |f_out|
                  f_out.write(hide_passwords(f_in.read))
                end
              end    
            else
              # Other kind of files are not touched.
              FileUtils.copy(f, dir)
            end
          end

          # Make the tar file.
          system("tar -zcvf #{tf.path} #{Dir[File.join(dir, "*")].join(" ")}")
        ensure
          # Remove the temporary directory.
          FileUtils.rm_rf(dir)
        end

        tf.seek(0, File::SEEK_SET)
        send_data(tf.read, 
                  :filename => "tbxsos.logs.tgz",
                  :type => "application/x-gzip")
      end
    else
      if File.exists?("/var/log/teambox/#{@active_log}")
        File.open("/var/log/teambox/#{@active_log}", "r") do |f|
          if params[:download].nil? # params[:view] go through here.
            begin
              content = hide_passwords(f.read)
              @lines = parse_log_lines(content.split("\n"))

              if @lines.length > 100
                @lines = @lines.slice -100, 100  # 100 last lines
              end
            rescue
              @lines = ['Failed to display the log file.']
            end          
          else
            content = hide_passwords(f.read)
            send_data(content, :filename => @active_log, :type => "text/plain")        
          end
        end
      else
        @lines = []
      end
    end
  end
end
