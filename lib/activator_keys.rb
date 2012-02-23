# -*- coding: utf-8 -*-
# activator_keys.rb --- Activation key management
# Copyright (C) 2006-2012 Opersys inc.  All rights reserved.

# Author: François-Denis Gonthier

require 'ezteambox'
require 'fileutils'

class ActivatorKeysException < Exception
end

class ActivatorKeys

  # Set the base working directory.
  def ActivatorKeys.basedir=(val)
    @@basedir = val
  end

  def initdir
    raise ActivatorKeysException("basedir not set") if @@basedir.nil?

    # Boolean stuff.
    @has_enc_pkey = File.exists?(@enc_pkey_path)
    @has_enc_skey = File.exists?(@enc_skey_path)
    @has_sig_pkey = File.exists?(@sig_pkey_path)
    @has_sig_skey = File.exists?(@sig_skey_path)

    # Check if we need to generate the keys.
    if !File.exists?(@keys_dir)
      FileUtils.mkdir_p(@keys_dir)
      
      # Generate the keys.
      EZTeambox.gen_keys(:enc, 0, @enc_key_zero_path_prefix, "unknown")
    end
  end

  def initialize(basename)
    @keys_dir = File.join(@@basedir, "keys", basename)
    
    # 0-id keys.
    @enc_key_zero_path_prefix = File.join(@keys_dir, "email.0")
    @enc_pkey_zero_path = File.join(@keys_dir, "email.0.enc.pkey")
    @enc_skey_zero_path = File.join(@keys_dir, "email.0.enc.skey")

    # Identified keys.
    @enc_pkey_path = File.join(@keys_dir, "email.enc.pkey")
    @enc_skey_path = File.join(@keys_dir, "email.enc.skey")
    @sig_pkey_path = File.join(@keys_dir, "email.sig.pkey")
    @sig_skey_path = File.join(@keys_dir, "email.sig.skey")

    initdir
  end

  def has_enc_skey
    return @has_enc_skey
  end

  def has_enc_pkey
    return @has_enc_pkey
  end

  # Return true if the set of key is complete.
  def has_complete_set?
    return @has_enc_pkey && @has_enc_skey && @has_sig_pkey && @has_sig_skey
  end

  # Path to the zero-numbered public key generated for activation.
  def kar_pkey_path
    return @enc_pkey_zero_path
  end

  # Path to the zero-numbered private key generated for activation.
  def kar_skey_path
    return @enc_skey_zero_path
  end
  
  def set_keyid(keyid)
    if !@has_enc_skey
      system("kctl keysetid #{@enc_skey_zero_path} #{keyid} #{@enc_skey_path} > /dev/null")
      system("kctl keysetid #{@enc_pkey_zero_path} #{keyid} #{@enc_pkey_path} > /dev/null")

      @has_enc_skey = true
      @has_enc_pkey = true

      if $? != 0
        raise ActivatorKeysException.new("failed to change key ID")
      end
    #don't care.. it can happen with backups  
    #else
    #  raise ActivatorKeysException.new("key ID already set")
    end
  end

  def get_keyid()
    begin
      File.open(@sig_pkey_path, "r") do |f|
        f.readline();
        key_id = f.readline().strip().to_i()
        f.close()
        return key_id
      end
    rescue
      return nil
    end
    return nil
  end

  def enc_pkey_path
    if File.exists?(@enc_pkey_path)
      return @enc_pkey_path
    else
      return nil
    end
  end

  def enc_skey_path
    if File.exists?(@enc_skey_path)
      return @enc_skey_path
    else
      return nil
    end
  end

  def sig_skey_path
    if File.exists?(@sig_skey_path)
      return @sig_skey_path
    else
      return nil
    end
  end

  def set_sig_skey(sig_skey_path)
    if !@has_sig_skey
      FileUtils.copy(sig_skey_path, @sig_skey_path)      
      @has_sig_skey = true
    #else
    #  raise ActivatorKeysException.new("already got a private signature key")
    end
  end

  def sig_pkey_path
    if File.exist?(@sig_pkey_path)
      return @sig_pkey_path
    else
      return nil
    end
  end

  def set_sig_pkey(sig_pkey_path)
    if !@has_sig_pkey
      FileUtils.copy(sig_pkey_path, @sig_pkey_path)
      @has_sig_pkey = true
    #else
    #  raise ActivatorKeysException.new("already got a public signature key")
    end
  end

  def reset
    if File.exists?(@keys_dir)
      FileUtils.rm_rf(@keys_dir)
      initdir
    end
  end

end
