# Copyright (C) 2007-2012 Opersys inc., All rights reserved.

module FileAsserts

  class FileAssertException < Exception
    def initialize(err)
      super(err)
    end
  end

  def FileAsserts.assert_file_readable(file_path)
    if not FileTest.exists?(file_path)
      raise FileAssertException.new("#{file_path} does not exists.")
    end
    if not FileTest.readable?(file_path)
      raise FileAssertException.new("#{file_path} is not readable.")
    end
  end

  def FileAsserts.assert_file_writable(file_path)
    if not FileTest.writable?(File.dirname(file_path))
      raise FileAssertException.new("#{file_path} cannot be created.")
    end
  end


  def FileAsserts.assert_file_creatable(file_path)
    if FileTest.exists?(file_path)
      raise FileAssertException.new("#{file_path} already exists.")
    end
    if not FileTest.writable?(File.dirname(file_path))
      raise FileAssertException.new("#{file_path} cannot be created.")
    end
  end

end
