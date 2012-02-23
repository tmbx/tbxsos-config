# Copyright (C) 2007-2012 Opersys inc., All rights reserved.

module file_upload
  def sanitize_filename(file_name)
    f = File.basename(file_name)
    f.sub(/[^\w\.\-]/,'_')
  end
end
