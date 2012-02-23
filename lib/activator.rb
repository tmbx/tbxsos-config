# -*- coding: utf-8 -*-
# activator.rb --- Main activation file.
# Copyright (C) 2006-2012 Opersys inc.  All rights reserved.

# Author: François-Denis Gonthier

require 'activator'
require 'activator_kar'
require 'kap'
require 'yaml'
require 'fileutils'
require 'kap_handler'

class ActivatorException < Exception
end

# Activation orchestrator. This class can be serialized in order to
# preserve the state of the activation process.

# FIXME: A lot of thing this class is doing would be much better of 
# done by the priviledged configuration daemon.
class Activator
  def Activator.basedir=(val)
    @@basedir = val
  end

  def Activator.teambox_ssl_cert_path=(val)
    @@teambox_ssl_cert_path = val
  end

  def Activator.teambox_sig_pkey_path=(val)
    @@teambox_sig_pkey_path = val
  end

  public

  attr_accessor :step, :name

  attr_reader :id_name

  # KAR attributes
  def admin_name
    return @identity.admin_name
  end

  def admin_name=(val)
    @identity.admin_name = val
  end

  def admin_email
    return @identity.admin_email
  end

  def admin_email=(val)
    @identity.admin_email = val
  end

  # CSR attributes.
  def country
    return @identity.country
  end

  def country=(val)
    @identity.country = val
  end

  def state
    return @identity.state
  end

  def state=(val)
    @identity.state = val
  end

  def location
    return @identity.location
  end

  def location=(val)
    @identity.location = val
  end

  def org
    return @identity.org
  end

  def org=(val)
    @identity.org = val
  end

  def org_unit
    return @identity.org_unit
  end

  def org_unit=(val)
    @identity.org_unit = val
  end

  def domain
    return @identity.domain
  end

  def domain=(val)
    @identity.domain = val
  end

  def email
    return @identity.email
  end

  def email=(val)
    @identity.email = val
  end

  def kdn
    return @identity.kdn
  end

  def keys
    return @keys
  end

  attr_writer :has_csr_key, :has_csr, :has_kar, :has_keys

  # Generate the Kryptiva Activation Request (KAR).  This will
  # generate the encryption keys if its not done yet.
  def make_kar
    # No-op.  Will be generated on call to @kar.get_kar
  end

  # Return the KAR for this activator.  The KAR content will be
  # encrypted with the parent's certificate if this activator was
  # created with a parent identity.
  def get_kar
    if not @parent_identity.nil? and not @parent_keys.nil?
      return @kar.get_kar(@parent_identity, @keys, @identity)
    else
      return @kar.get_kar(@identity, @keys, @identity)
    end
  end

  # Generate the keys.  This doesn't actually return anything but
  # allow the activator object handler to save the activator state an
  # thus not constantly regenerate keys.
  def make_keys
    # No-op.  Will be generated on construction of @keys
  end

  # Generate the CSR
  def make_csr
    # No-op.  Will be generated on call to @identity.get_csr
  end

  # Return the generated CSR as a string.
  def get_csr
    return @identity.get_csr
  end

  # Deletes a generated CSR
  def del_csr
    return @identity.del_csr
  end


  # decompress kap (use existing kap if nil)
  # handle kap
  def use_kap(kap_str = nil, install_bundle=true, kaptype=nil)
    @kar.use_kap(kap_str=kap_str, keys=@keys, identity=@identity, install_bundle=install_bundle, kaptype=kaptype)
  end

  # Return true of a KAP is matched to this activator.
  def activated?  
    # We need to check the step number of else we will skip the last
    # step.
    return (!@step.nil? and @step >= 7 and !@kar.kap.nil?)
  end

  # Return true if the activator has a parent.
  def has_parent?
    return !@parent_identity.nil?
  end

  # Save the certificate as a string in its target file.
  def set_cert(cert_str)
    @identity.set_cert(cert_str)
  end

  # Move the activator to the next step.
  def next_step
    @step = @step + 1
  end

  # Move the activator to the previous step.
  def previous_step
    @step = @step - 1
  end

  def clean_activation_dir
  end

  # This destroy all the data in the activation directory and the
  # related directories.
  def delete
    if File.exists?(@act_dir)
      if not @org_id.nil?
        begin
          # could fail... but should not, since we call delete only when we restart an activation
          org = Organization.find(@org_id)
          org.destroy
        rescue
          # do nothing
        end
      end
      @identity.reset
      @keys.reset
      @kar.reset

      FileUtils.rm_r(@act_dir) if File.exists?(@act_dir)
    end
  end

  def Activator.exists?(name)
    return File.exists?(File.join(@@basedir, "activation", name, "act_data"))
  end

  # Create the main or initial activator.
  def Activator.create_main
    activator = Activator.new(name = "main",
                              id_name = "main",
                              parent_id_name = nil,
                              keys_name = "main",
                              parent_keys_name = nil)
    activator.save
    return activator
  end

  # load or create activation
  def Activator.get_main
    activator = Activator.load_existing("main")
    if activator.nil?
      activator = Activator.create_main()
    end
    return activator
  end

  # Return true if the main activator has been activator.
  def Activator.has_activated_main?
    activator = Activator.load_existing("main")
    return (!activator.nil? and activator.activated?)
  end

  # Create a new activator with identity asserted by a parent.
  def Activator.create_new(parent_id_name = nil, parent_keys_name = nil)  
    activator = nil

    # Find a non-existing name.
    i = 1
    t = false
    s = ""
    while !t
      s = format("%04d", i)
      if not ActivatorIdentity.exists?(s)
        t = true
      end
      i += 1
    end      

    # Create the next activator.
    p = parent_id_name
    k = parent_keys_name
    activator = Activator.new(name = s, 
                              id_name = s,
                              parent_id_name = p,
                              keys_name = s,
                              parent_keys_name = k)
    activator.save
    
    return activator
  end

  # Return an hopefully meaningful name for the activator.
  def to_s
    if not @identity.org.nil?
      @identity.org
    else
      "unknown activation"
    end
  end

  def Activator.list
    raise ActivatorException("basedir not set") if @@basedir.nil?

    dn = File.join(@@basedir, "identity")
    if File.exists?(dn) and File.directory?(dn)
      Dir.chdir(dn) do
        (Dir.glob("*").map do |d|
          Activator.load_existing(d)
         end).reject do |d|
          if d.nil?
            true
          end
        end
      end
    else
      return nil
    end
  end

  # should use identities lib instead of loading file manually
  def Activator.load_kdn(kdn)
    return Activator.load_identity(:kdn, kdn)
  end

  def Activator.load_org(org_id)
    return Activator.load_identity(:org_id, org_id)
  end

  def Activator.load_identity(var, value)
    s = File.join(@@basedir, "identity", "*")
    Dir.glob(s).each do |d|
      id = File.basename(d)
      file = File.join(@@basedir, "identity", id, "id_data")
      if File.exists?(file)
        File.open(file, "r") do |f|
          tmpdata = YAML.load(f)
          if tmpdata[var].to_s == value.to_s
            return Activator.load_existing(id)
          end
        end
      end
    end
    return nil
  end


  # Load activation data for a given name. Returns nil if not found
  def Activator.load_act_data(name)
    # Initialize the static variables of sub-stuff.
    Activator.initialize_static
    # Load the current activator if no name has been provided.
    s = File.join(@@basedir, "activation", name, "act_data")
    if File.exists?(s)
      data = nil
      
      # Load the data file.
      File.open(s, "r") do |f|
        data = YAML.load(f)
      end
      return data
    end
    return nil
  end

  def Activator.main_org_kdn()
    act = Activator.load_existing("main")
    return act.kdn
  end

  # Load an activator given a name.  Will return nil if the activator
  # doesn't exists.
  def Activator.load_existing(name)
    # Initialize the static variables of sub-stuff.
    Activator.initialize_static

    data = Activator.load_act_data(name)
    if not data.nil?
      return Activator.new(name = data[:name], 
                           id_name = data[:id_name],
                           parent_id_name = data[:parent_id_name],
                           keys_name = data[:keys_name],
                           parent_keys_name = data[:parent_keys_name],
                           org_id = data[:org_id],
                           step = data[:step])
    end

    return nil
  end

  def save
    File.open(File.join(@@basedir, "activation", @name, "act_data"), "w") do |f|
      s = {
        :org_id => @org_id,
        :step => @step,
        :name => @name, 
        :id_name => @id_name,
        :keys_name => @keys_name,
        :parent_id_name => @parent_id_name,
        :parent_keys_name => @parent_keys_name
      }
      YAML.dump(s, f)
    end
  end

  # Initialize the static variables in the underlying classes.
  def Activator.initialize_static
    ActivatorKeys.basedir = @@basedir
    ActivatorIdentity.basedir = @@basedir
    ActivatorKAR.basedir = @@basedir
    ActivatorKAR.teambox_ssl_cert_path = @@teambox_ssl_cert_path
    
    KAP.teambox_sig_pkey_path = @@teambox_sig_pkey_path
  end

  private    

  def initialize(name, id_name, parent_id_name, keys_name, parent_keys_name, org_id = nil, step = nil)
    raise ActivatorException("basedir not set") if @@basedir.nil?

    # Initialize static variables in the utility classes.
    Activator.initialize_static

    @act_dir = File.join(@@basedir, "activation", name)

    # Create the directory the activator will be stored in.
    if not File.exists?(@act_dir)
      FileUtils.mkdir_p(@act_dir)
    end

    # Set the attribute of the activator.
    if org_id.nil?
        # create new organization in pending mode
        org = Organization.new()
        org.name = "pending_activation"
        org.status = Org.status_pending_activation
        org.save
        org_id = org.org_id
    end

    @org_id = org_id
    @name = name
    @id_name = id_name
    @keys_name = keys_name
    @parent_id_name = parent_id_name
    @parent_keys_name = parent_keys_name
    @step = 0
    @step = step unless step.nil?

    # Create the objects.
    @kar = ActivatorKAR.new(name)
    @identity = ActivatorIdentity.new(id_name)
    if @identity.org_id.nil?
      @identity.org_id = org_id
    end
    @keys = ActivatorKeys.new(keys_name)

    @parent_identity = nil
    if not parent_id_name.nil?
      @parent_identity = ActivatorIdentity.new(parent_id_name)
    end
    
    @parent_keys = nil
    if not parent_keys_name.nil?
      @parent_keys = ActivatorKeys.new(parent_keys_name)
    end
  end

end
