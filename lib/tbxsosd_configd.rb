# Copyright (C) 2007-2012 Opersys inc., All rights reserved.

require 'tempfile'

class NoDaemon < Exception
end

class TbxsosdConfigd

  private

  def initialize()
    @cmd_sock_name = TBXSOSD_CONFIGD_CMD_SOCKET
  end

  # write data to socket.. expect one line
  def sock_write_expect_line(out_data, in_expect)
    # Make sure the socket file exists.
    if !FileTest.exists?(@cmd_sock_name)
      raise NoDaemon.new
    end

    # Make sure we can connect
    begin
      sock = UNIXSocket.open @cmd_sock_name
    rescue
      raise NoDaemon.new
    end

    is_ok = false
    begin
      sock.print out_data
          line = sock.readline
      if line.strip == in_expect.strip
        is_ok = true
      end
    ensure
      sock.close
    end

    return is_ok
  end

  public

  def reboot
    return sock_write_expect_line("reboot\n", "ok")
  end

  def restart
    return sock_write_expect_line("rehash\n", "ok")
  end

  def set_date(year, month, day)
    fyear = "%04d" % year.to_i # yeah...
    fmonth = "%02d" % month.to_i
    fday = "%02d" % day.to_i

    return sock_write_expect_line("date\n#{fyear}\n#{fmonth}\n#{fday}\n", "ok")
  end

  def set_timezone(tz)
    return sock_write_expect_line("timezone\n#{tz}\n", "ok")
  end

  def set_time(hour, min, sec)
    fhour = "%02d" % hour.to_i
    fmin = "%02d" % min.to_i
    fsec = "%02d" % sec.to_i

    return sock_write_expect_line("time\n#{fhour}\n#{fmin}\n#{fsec}\n", "ok")
  end

  def update_bundle(file)
    return sock_write_expect_line("bundle_update\n#{file}\n", "ok")
  end

  def install_bundle(file)
    return sock_write_expect_line("bundle_install\n#{file}\n", "ok")
  end

  def switch_ssl_keys(key_file, cert_file)
    return sock_write_expect_line("ssl_key_switch\n#{key_file}\n#{cert_file}\n", "ok")
  end

  def convert_kps_backup(file_data)
    Tempfile.open("backup") do |backup_file|
      # Save the backup data in a temporary file.
      backup_file.write(file_data.read)
      backup_file.flush()

      # Call tbxsosd-configd
      return sock_write_expect_line("convert_kps_backup\n#{backup_file.path}\n", "ok")
    end
  end

end
