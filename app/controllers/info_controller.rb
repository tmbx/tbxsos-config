class InfoController < ApplicationController

  before_filter :init_menu

  # does not work in initialize
  def init_menu
    @menus.set_selected("dashboard")
  end


  layout "standard"

  def list
    @tbxsosd_running = false
    if File.exists?("/var/run/tbxsosd.pid")
      File.open("/var/run/tbxsosd.pid", "r") do |f|
        pid = f.read.to_i
        if File.exist?("/proc/#{pid}")
          @tbxsosd_running = true
        end
      end
    end      

    @user_auth_method_str

    c = ConfigOptions.new;
    p = Profil.find(:all)

    if Auth.ldap_enabled?()
	  @ldap = true
	  if Auth.ldap_type() == AUTH_LDAP_EXCHANGE
	    @user_auth_method_str = GTEH_("user.authentication.method.ldap_exchange")
	  else
        @user_auth_method_str = GTEH_("user.authentication.method.ldap_domino")
	  end
      @nb_users = "N/A"
    else
      @ldap = false
      @user_auth_method_str = GTEH_("user.authentication.method.local")
      @nb_users = p.length
    end


    begin
      license = License.from_kdn(Activator.main_org_kdn())
      @lic_lim = license.limit
      @lic_max = license.max
    rescue Exception => ex
      @no_license = GTEH_("activation.restore.no_license")
    end
    @seats_current = LoginSeats.find(:all)
  end

  def reboot
    begin
      kcd = TbxsosdConfigd.new
      if kcd.reboot
        flash[:notice] = GTEH_("info.reboot.ok")
      else
        flash[:error] = GTEH_("info.reboot.failed")
      end
    rescue
      flash[:error] = GTEH_("info.reboot.failed")
    end

    redirect_to :action => "list"
  end
end
