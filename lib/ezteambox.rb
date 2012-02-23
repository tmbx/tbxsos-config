# Copyright (C) 2007-2012 Opersys inc., All rights reserved.

require 'fileasserts'
require 'safeexec'

class EZTeamboxException < Exception
  def initialize(err)
    super(err)
  end
end

class EZTeambox
  include FileAsserts
  include SafeExec

  def EZTeambox.import_key(key_file_list) 
    key_file_list.each do |key_file|
      FileAsserts.assert_file_readable(key_file)

      begin
        cmd = "kctl importkey #{key_file}"
        SafeExec.exec(cmd)
      rescue SafeExecException => ex
        raise EZTeamboxException.new("kctl error: #{ex.stderr.to_s}")
      end
    end
  end

  def EZTeambox.gen_keys(key_type, key_id, key_prefix, owner)
    key_types_str = { :enc => "enc", :sig => "sig", :both => "both" }
    kt = key_types_str[key_type]

    if not kt
      raise EZTeamboxException.new("Unknown key type #{key_type}.")
    end

    if key_type == :sig or key_type == :both
      FileAsserts.assert_file_creatable("#{key_prefix}.sig.pkey")
      FileAsserts.assert_file_creatable("#{key_prefix}.sig.skey")
    end
    if key_type == :enc or key_type == :both
      FileAsserts.assert_file_creatable("#{key_prefix}.enc.pkey")
      FileAsserts.assert_file_creatable("#{key_prefix}.enc.skey")
    end

    begin
      cmd = "kctl genkeys " +
                       "#{kt} " +
                       "#{key_id} " +
                       "\"#{key_prefix}\" " +
                       "\"#{owner}\""
      SafeExec.exec(cmd)
    rescue SafeExecException => ex
      raise EZTeamboxException.new("kctl error: #{ex.stderr.to_s}")
    end
  end

  # That function wraps kpsinstalltool decrypt_verify.
  def EZTeambox.decrypt(pub_sign_key, priv_enc_key, input_file, output_file)
    FileAsserts.assert_file_readable(pub_sign_key)
    FileAsserts.assert_file_readable(priv_enc_key)
    FileAsserts.assert_file_readable(input_file)
    FileAsserts.assert_file_creatable(output_file)

    begin
      cmd = "kpsinstalltool decrypt_verify "+
                       "#{pub_sign_key} " +
                       "#{priv_enc_key} " +
                       "#{input_file} " +
                       "#{output_file}"
      SafeExec.exec(cmd)
    rescue SafeExecException => ex
      raise EZTeamboxException.new("kpsinstalltool error: #{ex.stderr.to_s}")
    end
  end
end
