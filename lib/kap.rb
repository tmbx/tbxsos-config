# -*- coding: utf-8 -*-
# kap.rb --- Activation package management.
# Copyright (C) 2006-2012 Opersys inc.  All rights reserved.

# Author: François-Denis Gonthier

require 'fileutils'
require 'workdir'
require 'ezteambox'

# This is a weirder class than the 3 others used to generate the KAR
# since the KAP might be used for something else than activation.  For
# that reason, it cannot keep a hard state, it is not bound to the
# activation process.  It thus needs to be decrypted everytime it is used.
#
# Care should be taken to minimize the number of times a KAP object is
# created.

# FIXME: For technical reasons, there is no unit test for this class,
# which is a bit of a problem. 

class KAPException < Exception
end

# FIXME: Not sure this works at all.
class KAPWorkdirNuker
  def destroy
    @wd.close
  end

  def initialize(wd)
    @wd = wd
  end
end

class KAP

  private
  
  # This is admitedly quite bizarre, but it saves me quite a bit of
  # redundant code.
  def file_or_nil(filename, var)
    if eval(var).nil?
      p = File.join(@kap_dir, "kap", filename)
      if File.exists?(p)
        File.open(p, "r") do |f|
          eval("#{var} = \"#{f.read}\"")
        end
      else
        eval("#{var} = false")
      end
    end

    if not eval(var)
      return nil
    else
      return eval(var)
    end
  end

  public

  # Create a new KAP object.  This requires you to pass the path to
  # the encryption key as parameter.
  def initialize(kap_str = nil, enc_skey_path = nil, basedir = nil, expand = false)
    if basedir.nil? and (kap_str.nil? or enc_skey_path.nil?)
      raise KAPException.new("incorrect KAP construction")
    end

    # If basedir is nil, then kap_str and enc_skey_path are simply
    # ignored, so no check is really needed.

    if basedir.nil? 
      @workdir = Workdir.new
      @workdir_path = @workdir.path
    else
      @workdir_path = basedir
    end

    # Register an asynchronous destructor to remove the temporary work
    # directory.
    ObjectSpace.define_finalizer(self, proc { @workdir.close unless @workdir.nil? })

    @kap_dir = @workdir_path
    @kap_enc_path = File.join(@kap_dir, "kap.bin")
    @kap_dec_path = File.join(@kap_dir, "kap.tar.gz")

    if !File.exists?(@kap_enc_path)
      if kap_str.nil?
        # no kap has been uploaded yet... 
        # no kap_str...
        # nothing to do
        return nil
      end
      # Write the KAP to disk.
      File.open(@kap_enc_path, "w") do |f|
        f.write(kap_str)
      end
    end
   
    #print "#{@@teambox_sig_pkey_path}\n"
    #print "#{enc_skey_path}\n"
    #print "#{@kap_enc_path}\n"
    #print "#{@kap_dec_path}\n"

    if !File.exists?(@kap_dec_path) and not expand
      return nil
    end

    if expand
      # Decrypt the KAP.
      EZTeambox.decrypt(@@teambox_sig_pkey_path,
                         enc_skey_path,
                         @kap_enc_path,
                         @kap_dec_path)

      # Extract the kap.tar.gz
      begin
        cmd = "tar -C #{@workdir_path} -zxvf #{@workdir_path}/kap.tar.gz "
        SafeExec.exec(cmd)
      rescue SafeExecException => ex
        raise KAPException.new("Failed to expand KAP file: #{ex.stderr.to_s}.")
      end
    end
  end

  # Close the working directory.
  def close
    @workdir.close
  end

  # Save the KAP state.  This creates a subdirectory called 'kap_name'
  # in 'basedir' where the expanded KAP files will be copied.
  # If KAP contents are already present, update
  # THIS IS NOT NEEDED FOR HANDLING KAP SINCE IT'S DONE IN A TMP WORKDIR 
  def save_contents(kap_name, basedir, save_all=true)
    @kap_dir = File.join(basedir, kap_name)

    # Thank god for Ruby.
    FileUtils.mkdir_p(@kap_dir)
    if save_all
      FileUtils.cp_r(File.join(@workdir_path, "."), @kap_dir)
    else
      # save only kap
      FileUtils.cp_r(File.join(@workdir_path, "kap.bin"), @kap_dir)
    end
  end

  # License limit, nil if there is nothing about that in the KAP.
  def license_lim
    return file_or_nil("license_lim", "@license_lim").to_i
  end

  # License maximum, nil if there is nothing about that in the KAP.
  def license_max
    return file_or_nil("license_max", "@license_max").to_i
  end

  # Return the web update username or nil from the KAP.
  def web_username
    return file_or_nil("web_user", "@web_username")
  end

  # Return the web update password or nil from the KAP.
  def web_password
    return file_or_nil("web_pwd", "@web_password")
  end

  # Return the key ID or nil from the KAP.
  def keyid
    return file_or_nil("keyid", "@keyid").to_i
  end

  # Return the KDN or nil from the KAP.
  def kdn
    return file_or_nil("kdn", "@kdn")
  end

  # Return the content of the license.
  def license_path
    lpath = File.join(@kap_dir, "kap", "lic")
    if File.exists?(lpath)
      return lpath
    else
      return nil
    end
  end

  # Return the path to the bundle file or nil if there were no bundles in the KAP.
  def bundle_path
    bpath = File.join(@kap_dir, "kap", "kps.bundle")
    if File.exists?(bpath)
      return bpath
    else
      return nil
    end
  end

  def enc_pkey_path
    pkey = File.join(@kap_dir, "kap", "keys", "email.enc.pkey")
    if File.exists?(pkey)
      return pkey
    else
      return nil
    end
  end

  def sig_skey_path
    skey = File.join(@kap_dir, "kap", "keys", "email.sig.skey")
    if File.exists?(skey)
      return skey
    else
      return nil
    end
  end

  def sig_pkey_path
    pkey = File.join(@kap_dir, "kap", "keys", "email.sig.pkey")
    if File.exists?(pkey)
      return pkey
    else
      return nil
    end
  end

  def KAP.teambox_sig_pkey_path=(val)
    @@teambox_sig_pkey_path = val
  end

  # Load the KAP state.
  def KAP.load(kap_name, basedir)
    return KAP.new(nil, nil, File.join(basedir, kap_name))
  end
end
