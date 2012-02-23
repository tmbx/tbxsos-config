# Copyright (C) 2007-2012 Opersys inc., All rights reserved.

require 'fileutils'

class Workdir
  
  # Copy a file somewhere else on the system to the specified path
  # relative to the workdir path.  The path should include the file's
  # name.
  def copy_file(file_path, rel_path)
    path = File.join(@base_dir, @name, rel_path)
    dirname = File.dirname(path)

    FileUtils.mkdir_p(dirname)
    FileUtils.copy(file_path, path)
  end

  # Add a file as string in the workdir to the specified path relative
  # to the workdir path.  The path should include the file's name.
  def add_file(file_content, rel_path)
    path = File.join(@base_dir, @name, rel_path)
    dirname = File.dirname(path)

    FileUtils.mkdir_p(dirname)
    File.open(path, "w") do |f|
      f.write(file_content)
    end
  end

  # Tar-up the temporary directory.
  def tar(filename)
    if filename.match(".*\.bz2")
      compress = 'j'
    elsif filename.match(".*\.gz")
      compress = 'z'
    elsif filename.match(".*\.tar")
      compress = ''
    else
      throw Exception.new("Don't know what compression type to use (tgz/tbz2/tar).")
    end

    # TODO: Replace system by Popen3.
    system("tar -C #{@base_dir}/#{@name} "\
           + "-#{compress}cvf #{filename} "\
           + ".")
#           + "`(cd #{@base_dir}/#{@name} && find ! -name '.')`")
    return File.exists?("#{@base_dir}/#{filename}")
  end

  def path
    return File.join(@base_dir, @name)
  end

  def to_s
    return path
  end

  # Delete the content of the temporary directory.
  def close
    if @base_dir !~ /^\/tmp/
      raise Exception.new("Workdir won't erase anything outside /tmp.")
    end
    system("rm -rf #{@base_dir}/#{@name}/*")
    Dir.rmdir("#{@base_dir}/#{@name}")
  end

  def initialize(base_dir = "/tmp", name = nil)
    if !name
      @name = `cat /proc/sys/kernel/random/uuid`.strip
    else
      @name = name
    end
    @base_dir = base_dir
    Dir.mkdir("#{base_dir}/#{@name}")
  end
end
