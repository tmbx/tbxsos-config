#
# archive and install bundles
#

require 'fileutils'
require 'tbxsosd_configd'

module Bundle
  # called by the applications controller to init needed variables
  def Bundle.archive_dir=(val)
    @@archive_dir = val
    FileUtils.mkdir_p(@@archive_dir)
  end

  # install a single bundle
  def Bundle.install_bundle(bundle_file)
    begin
      cfgd = TbxsosdConfigd.new
      if not cfgd.install_bundle bundle_file
        raise Exception.new("could not install bundle")
      end
    rescue Exception => ex
      KLOGGER.info(ex.to_s)
      raise Exception.new("could not install bundle")
    end
  end

  # archive a bundle
  #def Bundle.archive_bundle(bundle_file)
  #  i = File.stat(bundle_file).mtime.to_i
  #  stamp = Time.at(i).strftime("%Y-%m-%d-%H-%M-%S")
  #  newfilename = "kps.bundle.#{stamp}"
  #  if not FileTest.exists?(newfilename)
  #    FileUtils.rm_f(File.join(@@archive_dir, newfilename))
  #    FileUtils.cp(bundle_file, File.join(@@archive_dir, newfilename))
  #  end
  #end

  # shortcut
  def Bundle.handle_bundle(bundle_file)
    #Bundle.archive_bundle(bundle_file)
    Bundle.install_bundle(bundle_file)
  end

  def Bundle.set_last_kap_bundle(bundle_file)
    fname = "kps.bundle.last_kap"
    fpath = File.join(@@archive_dir, fname)
    FileUtils.rm_f(fpath)
    FileUtils.cp(bundle_file, fpath)
  end

  def Bundle.install_last_kap_bundle()
    fname = "kps.bundle.last_kap"
    fpath = File.join(@@archive_dir, fname)
    Bundle.install_bundle(fpath)
  end

  # install all archived bundles (for restore based activations)
  #def Bundle.install_archived_bundles()
  #  begin
  #    cfgd = TbxsosdConfigd.new
  #    cfgd.install_bundles @@archive_dir
  #  rescue Exception => ex
  #    KLOGGER.info(ex.to_s)
  #    raise Exception.new("could not install bundles")
  #  end
  #end
end

