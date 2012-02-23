# -*- coding: utf-8 -*-
# options.rb
# Copyright (C) 2007-2012 Opersys inc., All rights reserved.
#
# Option model
#
# @author François-Denis Gonthier

require 'safeexec'
require 'auth'

class ConfigOptions
  include SafeExec
  include Auth

  private

  class Value
    def initialize
      @saveable = false
      @has_changed = false
      @value = nil
      @value_at_load = nil
    end

    def isSaveable()
      @saveable
    end
    def setSaveable(val)
      @saveable = val
    end

    def getValue()
      @value
    end
    def setValue(val)
      @value = val
    end

    def getValueAtLoad()
      @value_at_load
    end
    def setValueAtLoad(val)
      @value_at_load = val
    end

    def hasChanged
      @has_changed
    end
    def setChanged(val)
      @has_changed = val
    end
 end

  def load_file(io, saveable = false)
    lines = io.readlines

    lines.each do |line|
      if line =~ /.*=.*/
        # eh, very weird ASCII boobs
        line =~ /(.*)=.*"(.*)";/
        if $1 != nil and $2 != nil
          key = $1
          val = $2

          v = Value.new
          v.setValue(val.strip)
          v.setValueAtLoad(val.strip)
          v.setSaveable(saveable)
          v.setChanged(false)

          @options[key.strip] = v
        end
      end
    end
  end

  public

  # Load options.
  def initialize
    @options = { }

    # Open tbxsosd.conf, then read all lines, EXCEPT the
    # include(web.conf) directive.
    m4_proc = KPopen3.new("m4 -I#{CONF_DIR}")    
    m4_in, m4_out, m4_err = m4_proc.pipes
    File.open("#{CONF_DIR}/tbxsosd.conf") do |e|
      e.readlines.each do |line|
        if line !~ /include(web.conf)/
          m4_in.print line
        end
      end
    end      
    m4_in.close
    # Use m4 to parse the 'include' directives.
    load_file(m4_out)

    # Oooh ruby OOoo.  Calls close on each pipes and the process.
    [m4_out, m4_err, m4_proc].each do |p|
      p.close
    end

    # Open the local configuration file.
    File.open("#{CONF_DIR}/web.conf") do |e|
      load_file(e, true)
    end
  end

  # Get an option string.
  def get(key)
    val = @options[key]

    if val
      val.getValue
    else
      ""
    end
  end

  def get_match(regexp)
    list = {}
    @options.each do |key, opt|
      if key =~ regexp
        list[key] = opt.getValue
      end
    end
    return list
  end

  # Set an option string, setting its changed flag in the same blow.
  def set(key, newValue)
    newValue = newValue.gsub(/[\"\n\r]/, "") # strips some bad characters
    v = @options[key]

    if !v
      v = Value.new
      @options[key] = v
    end

    v.setValue(newValue)
    v.setSaveable(true)
    v.setChanged(true)
  end

  def save
    # Open the target file
    f = File.open(CONF_DIR + '/' + CONF_FILE, "w")

    @options.keys.each do |key|
      if @options[key].isSaveable == true
        val = @options[key].getValue
        val_at_load = @options[key].getValueAtLoad
        if (@options[key].hasChanged == true)
          KLOGGER.info GT_("logs.config.save.option_value_changed") % [ key, val_at_load, val ]
        else
          KLOGGER.info GT_("logs.config.save.option_value") % [ key, val ]
        end
        s = "#{key} = \"#{val}\";"
        f.write "#{s}\n"
      end
    end
    f.close

    nil
  end

  def display_list(items)
    return nil if items.nil?
    return items.gsub(/ /, "\n")
  end

  def infilter_list(items)
    return nil if items.nil?
    return items.gsub(/[\s\r\n]+/, " ")
  end



  #### could be put somewhere else ####
  def validate_domain(domain)
    if (domain =~  /^[a-zA-Z0-9\.-]+$/) == nil
      return false
    end
    return true
  end

  def validate_ip(ip)
    if ! ip.nil?
      a,b,c,d = ip.split(".")
      if ! a.nil? && ! b.nil? && ! c.nil? && ! d.nil?
        
        if (a.to_i > 0 && a.to_i < 255 \
            && b.to_i > 0 && b.to_i < 255 \
            && c.to_i > 0 && c.to_i < 255 \
            && d.to_i > 0 && d.to_i < 255)
          return true
        end
      end
    end
    return false
  end


  def validate_host(host)
    if validate_domain(host) # || validate_ip(host) # anything that looks like an ip is accepted as a domain anyway...
      return true
    end
    return false
  end

  def validate_port(port)
    if ! port.nil?
      if port.to_i > 0 && port.to_i <= 65535
        return true
      end
    end
    return false
  end

  def validate_domains(domains)
    if domains.strip() == ""
      return ""
    end
    domains = domains.split(" ")
    ok = 0
    domains.each do |domain|
      if validate_domain(domain) != true
        return nil
      else
        ok = 1
      end
    end

    # make sure there is at least one domain
    if ok == 1
      return domains.join(" ")
    end
    return nil
  end


  def validate_hostsports(items)
    items.split(" ") do |item|
      host,port = item.split(":")
      if validate_host(host) != true || validate_port(port) != true
        return nil
      end
    end
    return items.join(" ")
  end

  # get forms,fields definitions
  def get_fw_forms_specs(fw)

    ### BASIC OPTIONS ###
    fo = fw.add_form("basic_options")

    fi = fo.add_field("server_password", "password", { "autofocus" => true, "required" => true })
    fi.reference = "server.password"

    fi = fo.add_field("server_passverif", "password", { "required" => true })
    #fi.reference = "" # only for verification - does not correspond to an option
    fi.verification_field = "server_password"

    fi = fo.add_field("server_allow_html", "checkbox")
    fi.reference = "server.allow_html"

    fi = fo.add_field("auth_mode", "radio", { "required" => true } )
    fi.realtype = "multiline"
    fi.choices = [
                   { "key" => AUTH_LOCAL_DATABASE, "value" => GTEH_("forms.basic_options.auth_mode.choices.kpsdb")},
                   { "key" => AUTH_LDAP_EXCHANGE, "value" => GTEH_("forms.basic_options.auth_mode.choices.ldap_exchange") },
                   { "key" => AUTH_LDAP_DOMINO, "value" => GTEH_("forms.basic_options.auth_mode.choices.ldap_domino") }
                 ]
    # retro compat -- should be something like auth.mode
    fi.reference = "ldap.enabled"

	# kas
	fi = fo.add_field("kas_address", "text")
	fi.reference = "server.kas_address"
	
	fi = fo.add_field("kas_port", "text")
	fi.reference = "server.kas_port"
	fi.default = 443

    ### UPDATE OPTIONS ###
    fo = fw.add_form("update_options")

    #fi = fo.add_field("server_daily_updates", "checkbox")
    #fi.reference = "server.daily_updates"

    #fi = fo.add_field("server_update_site", "text", { "size" => 30 })
    #fi.reference = "server.update_site"

    #fi = fo.add_field("server_update_username", "text", { "size" => 30 })
    #fi.reference = "server.update_username"
    
    #fi = fo.add_field("server_update_password", "password", { "size" => 30 })
    #fi.reference = "server.update_password"

    #fi = fo.add_field("ldap_sys_password_verif", "password", { "size" => 30 })
    #fi.verification_field = "server_update_password"

    ### TEAMBOX OPTIONS ###
    fo = fw.add_form("identities_options")

    # removed 2007-12-03 - mail received from Ragui
    #fi = fo.add_field("server_kdn", "text", { "size" => 35,
    #   "tags" => {"onfocus" => 
    #     "alert('#{GTEH_("forms.identities_options.server_kdn.help")}'); this.onfocus = '';" }
    #  })
    #fi.readonly = true
    #fi.reference = "server.kdn"

    fi = fo.add_field("server_domains", "textarea",
                      {
                        "required" => false,
                        "autofocus" => true,
                        "rows" => 3,
                        "cols" => 35
                      })
    fi.infilterfunc = lambda {|arg| return infilter_list(arg)}
    fi.validfunc = lambda {|arg| return validate_domains(arg)}
    fi.displayfunc = lambda {|arg| return display_list(arg)}
    fi.reference = "server.domains"

    ### LDAP OPTIONS ###
    fo = fw.add_form("ldap_options")

    if Auth.ldap_type() == AUTH_LDAP_EXCHANGE
        fi = fo.add_field("ldap_domain_search", "checkbox")
        fi.reference = "ldap.domain_search"

        fi = fo.add_field("ldap_domain", "text", { "required" => true, "autofocus" => true, "size" => 39 })
        fi.reference = "ldap.domain"
	elsif Auth.ldap_type() == AUTH_LDAP_DOMINO
        fi = fo.add_field("ldap_domain_search", "fake", { "force_value" => "0" })
        fi.reference = "ldap.domain_search"

        fi = fo.add_field("ldap_domain", "fake", { "force_value" => "" })
        fi.reference = "ldap.domain"
    end

    fi = fo.add_field("ldap_host", "textarea", { "required" => true, "rows" => 3, "cols" => 31 })
    fi.infilterfunc = lambda {|arg| return infilter_list(arg)}
    fi.validfunc = lambda {|arg| return validate_hostsports(arg)}
    fi.displayfunc = lambda {|arg| return display_list(arg)}
    fi.reference = "ldap.host"

    if Auth.ldap_type() == AUTH_LDAP_EXCHANGE
      fi = fo.add_field("ldap_use_tls", "checkbox")
      fi.reference = "ldap.use_tls"

      fi = fo.add_field("ldap_use_sasl", "checkbox")
      fi.reference = "ldap.use_sasl"

      fi = fo.add_field("ldap_dn_base", "fake", { "force_value" => "" })
      fi.reference = "ldap.dn_base"

    elsif Auth.ldap_type() == AUTH_LDAP_DOMINO
      fi = fo.add_field("ldap_use_tls", "fake", { "force_value" => "0" })
      fi.reference = "ldap.use_tls"

      fi = fo.add_field("ldap_use_sasl", "fake", { "force_value" => "0" })
      fi.reference = "ldap.use_sasl"

      # This is required only for Domino, where we can't find it
      # automatically.
      fi = fo.add_field("ldap_dn_base", "text", { "required" => true, "size" => 39 })
      fi.reference = "ldap.dn_base"
    end

    fi = fo.add_field("ldap_sys_dn", "text", { "required" => true, "size" => 39 })
    fi.reference = "ldap.sys_dn"

    if Auth.ldap_type() == AUTH_LDAP_EXCHANGE
        fi = fo.add_field("ldap_sys_username", "text", { "required" => true, "size" => 39 })
        fi.reference = "ldap.sys_username"
    elsif Auth.ldap_type() == AUTH_LDAP_DOMINO
        fi = fo.add_field("ldap_sys_username", "fake", { "force_value" => "" })
        fi.reference = "ldap.sys_username"
    end

    fi = fo.add_field("ldap_sys_password", "password", { "required" => true, "size" => 39 })
    fi.reference = "ldap.sys_password"

    fi = fo.add_field("ldap_sys_password_verif", "password", { "required" => true, "size" => 39 })
    fi.verification_field = "ldap_sys_password"

    if Auth.ldap_type() == AUTH_LDAP_EXCHANGE
		fi = fo.add_field("ldap_strict_address", "fake", { "force_value" => "0" })
		fi.reference = "ldap.strict_address"
	elsif Auth.ldap_type() == AUTH_LDAP_DOMINO
		fi = fo.add_field("ldap_strict_address", "checkbox")
		fi.reference = "ldap.strict_address"
	end

    return fw
  end


  # fill default values before showing form
  def set_field_values_from_options(fw, optgroup)
    # regular fields which have a reference to the actual config options
    fw.forms[optgroup].fields.each do |idfield, fi|
      if ! fi.reference.nil?
        # get value
        config_name = fi.reference
        tmp_value = get(config_name)

        # decodes value if needed
        if fi.type == "checkbox"
          if tmp_value.to_s == 1.to_s
            tmp_value = true
          else
            tmp_value = false
          end
        end

        # save
        fi.value = tmp_value
      end
    end

    # verification fields (manually fill - they are related to another field and not a config option)
    fw.forms[optgroup].fields.each do |idfield, fi|
      if ! fi.verification_field.nil?
        fi.value =  fw.forms[optgroup].fields[fi.verification_field].value # verification pass
      end
    end

    return fw
  end


  # save config options from the fields definition
  def save_config_from_form(fw, optgroup)
    fw.forms[optgroup].fields.each do |idfield, fi|
      if ! fi.reference.nil?
        # get value
        tmp_value = fi.value

        # encode value if needed
        if fi.type == "checkbox"
          if fi.value == true
            tmp_value = "1"
          else
            tmp_value = "0"
          end
        end

        # save if changed
        if get(fi.reference).to_s != tmp_value
          set(fi.reference, tmp_value)
        end
      end
    end

    save
  end


end



