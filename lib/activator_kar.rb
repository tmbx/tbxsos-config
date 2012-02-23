# -*- coding: utf-8 -*-
# activator_kar.rb --- Activation KAR generator class.
# Copyright (C) 2006-2012 Opersys inc.  All rights reserved.

# Author: François-Denis Gonthier

require 'fileutils'
require 'ezssl'
require 'workdir'

require 'activator_keys'
require 'activator_identity'
require 'kap_handler'

class ActivatorKARException < Exception
end

class ActivatorKAR

  def ActivatorKAR.basedir=(val)
    @@basedir = val
  end

  def ActivatorKAR.teambox_ssl_cert_path=(val)
    @@teambox_ssl_cert_path = val
  end

  private

  def ActivatorKAR.exists?(name)
    return File.exists?(File.join(@@basedir, "kar", name))
  end

  # Make the decrypted KAR content.  This produre assumes that
  # identity == wrapped_identity in case there is no parent identity.
  def make_dec_kar(identity, keys, wrapped_identity)
    if !File.exists?(@kar_dec_file_path)
      tmp = Workdir.new

      # Add the certificate.
      tmp.add_file(identity.get_cert, "kar/cert.pem")

      # Write the KDN of the parent identity if it's not the same has
      # the wrapped identity.
      if identity.kdn != wrapped_identity.kdn
        tmp.add_file(identity.kdn, "kar/parent_kdn")
      end
        
      # FIXME: We need that information, but I'm not sure this is a
      # good way to provide it.
      s = ["This is an activation done on the behalf of this organization:\n",
           "Country: ", wrapped_identity.country, "\n",
           "State: ", wrapped_identity.state, "\n",
           "Loc: ", wrapped_identity.location, "\n",
           "Org: ", wrapped_identity.org, "\n",
           "Org Unit: ", wrapped_identity.org_unit, "\n",
           "Domain: ", wrapped_identity.domain, "\n",
           "Email: ", wrapped_identity.email, "\n"]
      tmp.add_file(s.join, "kar/info")

      # Add the adminstrator information.     
      s = "#{wrapped_identity.admin_name} <#{wrapped_identity.admin_email}>"
      tmp.add_file(s, "kar/admin")

      # Add the product information.
      if File.exists?("/etc/teambox/product_version")
        tmp.copy_file("/etc/teambox/product_version", "kar/product_version")
      end
      if File.exists?("/etc/teambox/product_name")
        tmp.copy_file("/etc/teambox/product_name", "kar/product_name")
      end
        
      # Add the encryption key.
      tmp.copy_file(keys.kar_pkey_path, "kar/kar.enc.pkey")

      tmp.tar(@kar_dec_file_path)   
      tmp.close
    end
  end

  # Make the signed KAR file.
  def make_signed_kar(identity)
    if !File.exists?(@kar_sig_file_path)
      # Another directory to sign the tarball.
      tmp = Workdir.new
      
      # Sign the KAR tarball, giving a new tarball.
      tmp.copy_file(@kar_dec_file_path, "kar.tar.gz")

      # Get the hash of the decrypted KAR content.
      EZSSL.digest(@kar_dec_file_path, "#{tmp.to_s}/kar_hash")

      # Sign the hash content with sslsigntool.
      begin
        # FIXME: Move to EZSSL.
        cmd = "sslsigntool sign #{identity.get_cert_path} #{identity.get_key_path} " +
          "#{tmp.to_s}/kar_hash #{tmp.to_s}/kar_sig"
        SafeExec.exec(cmd)
      rescue SafeExecException => ex
        raise ActivatorKARException.new("Failed to sign KAR file: #{ex.stderr.to_s}")
      end

      # Tar-up and close the signed KAR.
      tmp.tar(@kar_sig_file_path)
      tmp.close
    end
  end

  # Make the encrypted KAR file.
  def make_encrypted_kar
    if !File.exists?(@kar_enc_file_path)
      EZSSL.smime_encrypt(@@teambox_ssl_cert_path, 
                          @kar_sig_file_path, 
                          @kar_enc_file_path)
    end
  end

  public

  # Attributes
  
  attr_reader :kar_dir, :name, :kap

  # Get the KAR as a string.
  def get_kar(identity, keys, wrapped_identity)
    if identity.has_cert?
      # Those operations will be no-op if they were done once.
      make_dec_kar(identity, keys, wrapped_identity)
      make_signed_kar(identity)
      make_encrypted_kar

      kar_str = ""
      File.open(@kar_enc_file_path, "r") do |f|
        kar_str = f.read
      end
      return kar_str
    else
      return nil
    end
  end

  # Set the KAP as a string.  Prevents override of the KAP has already
  # been set for this KAR.
  def use_kap(kap_str, keys, identity, install_bundle, kaptype)
    if kap_str.nil?
      # use existing kap (restoring from backup)
      File.open(@kap_dir+'/kap.bin', "r") do |kap_file|
        kap_str = kap_file.read()
      end
    end

    if kaptype.nil?
      kaptype = "main"
    end

    # Create the KAP object and save it outright.
    # OVERWRITE!!! THIS IS WANTED!!!
    @kap = KAP.new(kap_str, keys.kar_skey_path, nil, true) 

    # handle the kap in its temporary state
    kh = KAPHandler.new(@kap, identity, keys)
    if kaptype == "main"
      KLOGGER.info("Handling main KAP")
      kh.handle_kap_main(install_bundle)
    elsif kaptype == "other"
      KLOGGER.info("Handling KAP")
      kh.handle_kap()
    else
      KLOGGER.info("Invalid KAP type")
    end

    # save kap
    @kap.save_contents("kap", @kar_dir, false) # save only kap
    # @kap.save_contents("kap", @kar_dir, true) # save all kap files (debugging only)
  end

  def reset
    # Delete the whole KAR directory.
    if File.exists?(@kar_dir)
      FileUtils.rm_rf(@kar_dir)
    end

    initdir
  end

  def initdir
    if not File.exists?(@kar_dir)
      FileUtils.mkdir_p(@kar_dir)
    end

    # returns nil if not ok
    @kap = KAP.load("kap", @kar_dir)
  end

  def initialize(name)  
    # Set the working directory for KAR
    @kar_dir = File.join(@@basedir, "kar", name)
    @kap_dir = File.join(@kar_dir, "kap")
    @kar_data_file_path = File.join(@kar_dir, "kar_data")
    @kar_dec_file_path = File.join(@kar_dir, "kar.tar.gz")
    @kar_sig_file_path = File.join(@kar_dir, "signed_kar.tar")
    @kar_enc_file_path = File.join(@kar_dir, "kar.bin")

    initdir
  end

end
