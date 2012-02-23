require 'bundle'
require 'safeexec'
require 'fileasserts'

class KAPHandler
  private

  def handle_web_username()
    if not @kap.web_username.nil?   
      KLOGGER.info("KAP handling: changing web user")
      o = ConfigOptions.new
      o.set("server.update_username", @kap.web_username)
      o.save
    end
  end

  def handle_web_password()
    if not @kap.web_password.nil?
      KLOGGER.info("KAP handling: changing web password")
      o = ConfigOptions.new
      o.set("server.update_password", @kap.web_password)
      o.save
    end
  end

  def handle_license(force=false)
    if not @kap.license_path.nil?
      KLOGGER.info("KAP handling: changing license")
      # Calls KCTL to import the license.
      FileAsserts.assert_file_readable(@kap.license_path)
      begin
        cmd = "kctl importlicense #{@kap.license_path}"
        SafeExec.exec(cmd)
        return
      rescue Exception => ex
        KLOGGER.error("kctl error: #{ex.stderr.to_s}")
        raise Exception.new("Could not handle license.")
        return
      end
    end
    if force
      raise Exception.new("No license available in KAP file.")
    end
  end

  def handle_kdn()
    if not @kap.kdn.nil?
      KLOGGER.info("KAP handling: changing kdn")
      o = ConfigOptions.new

      # main kdn
      if o.get("server.kdn") == ""        
        o.set("server.kdn", @kap.kdn)
        o.save
      end

      # set org kdn
      org = Organization.find(@identity.org_id)
      org.name = @kap.kdn
      org.status = Org.status_activated
      org.save

      # Set the KDN in the identity.
      @identity.kdn = @kap.kdn
    end
  end


  def handle_bundle()
    if File.exists?(@kap.bundle_path.to_s) and ENV['RAILS_ENV'] == "production"
      KLOGGER.info("KAP handling: installing/updating from bundle")
      Bundle.set_last_kap_bundle(@kap.bundle_path)
      Bundle.handle_bundle(@kap.bundle_path)
    end
  end

  def handle_keys()
    if not @kap.keyid.nil?    
      KLOGGER.info("KAP handling: changing keys")
      # Set the key ID
      @keys.set_keyid(@kap.keyid)

      # Copy the signature keys.
      @keys.set_sig_pkey(@kap.sig_pkey_path)
      @keys.set_sig_skey(@kap.sig_skey_path)

      # Import the keys.
      EZTeambox.import_key([@keys.sig_pkey_path, @keys.sig_skey_path, 
                             @keys.enc_pkey_path, @keys.enc_skey_path])
    end
  end

  public

  def handle_kap_main(install_bundle)
    if @kap.nil? or @identity.nil? or @keys.nil?
      raise Exception.new("KAPHandler instance not initialized properly.")
    end
    handle_web_username()
    handle_web_password()
    handle_kdn()
    handle_license()
    if install_bundle
      handle_bundle()
    end
    handle_keys()
  end

  def handle_kap()
    if @kap.nil? or @identity.nil? or @keys.nil?
      raise Exception.new("KAPHandler instance not initialized properly.")
    end
    handle_kdn()
    handle_license()
    handle_keys()
  end

  def initialize(kap, identity, keys)
    @kap = kap
    @identity = identity
    @keys = keys
  end
end
