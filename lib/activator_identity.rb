# Copyright (C) 2007-2012 Opersys inc., All rights reserved.

# Assert identity with SSL certificates.
#
# This bizarre class was made to seperate identity assertion with SSL
# certification with the rest of the activation process.  My idea of
# identity assertion is that once it is done, it can be reused for
# other activation.
#
# To use that class, set the CSR parameters (country, location, etc),
# then call get_csr to obtain the CSR as text.  Once get_csr was
# called, the CSR attributes become read-only and attempts to write
# will raise ActivatorIdentityException.  This was made to protect the
# generated CSR and the key.
#
# Once an identity of a certain name has been created, any subsequent
# object creation with the same name will reload that identity.

require 'ezssl'
require 'fileutils'

class ActivatorIdentityException < Exception
end

class ActivatorIdentityCertException < Exception

  # Certificate is flat-out invalid for some reason.
  attr_accessor :is_invalid

  # Certificate might be valid for we cannot use it for some reason.
  attr_accessor :is_incorrect

  def initialize(is_invalid, is_incorrect)
    @is_invalid = is_invalid
    @is_incorrect = is_incorrect
  end
end

class ActivatorIdentity

  # Allow to set the base working directory
  def ActivatorIdentity.basedir=(val)
    @@basedir = val
  end

  # Return the list of identities.
  def ActivatorIdentity.list
    raise ActivatorIdentityException("basedir not set") if @@basedir.nil?

    dn = File.join(@@basedir, "identity")
    if File.exists?(dn) and File.directory?(dn)
      Dir.chdir(dn) do
        return Dir.glob("*").map do |d|
          if d != "." or d != ".."
            ActivatorIdentity.new(d)
          end
        end
      end 
    else
      return nil
    end
  end

  def ActivatorIdentity.exists?(name)
    raise ActivatorException("basedir not set") if @@basedir.nil?
    
    d = File.join(@@basedir, "identity", name)
    return (File.exists?(d) and File.directory?(d))
  end
      
  private

  def check_cert_key_match_csr_key
    begin
      cmd = "sslsigntool check_match #{@csr_file_path} #{@cert_file_path}"
      SafeExec.exec(cmd)
    rescue Exception => ex
      raise ActivatorIdentityCertException.new(is_invalid = false, is_incorrect = true)
    end

    if $? == 0
      return true
    end

    return false
  end

  def check_cert
    Tempfile.open("cert_check") do |t|
      return EZSSL.check_cert(@key_file_path, @cert_file_path, t.path)
    end
  end

  # Create a new identity or load an existing one.
  def initialize(id_name)
    raise ActivatorIdentityException("basedir not set") if @@basedir.nil?

    @identity_dir = File.join(@@basedir, "identity", id_name)

    @org_id = nil
    @csr = EZSSL_CSR.new
    @key_file_path = File.join(@identity_dir, "key")
    @cert_file_path = File.join(@identity_dir, "cert")
    @csr_file_path = File.join(@identity_dir, "csr")
    @csr_data_file_path = File.join(@identity_dir, "csr_data")                          
    @id_data_file_path = File.join(@identity_dir, "id_data")
    @id_name = id_name


    @files_to_clean = [@csr_file_path,
                       @cert_file_path,
                       # @key_file_path, ## do not delete - ever
                       @cert_file_path,
                       @csr_file_path,
                       @csr_data_file_path,
                       @id_data_file_path]

    @admin_email = nil
    @admin_name = nil

    # Check if the identity exists.
    if File.exists?(@identity_dir) 
      if File.exists?(@csr_data_file_path)
        @csr.load_csr_data(@csr_data_file_path)
      end
      
      if File.exists?(@id_data_file_path)
        File.open(@id_data_file_path, "r") do |f|
          s = YAML.load(f)
          @admin_email = s[:admin_email]
          @admin_name = s[:admin_name]
          @kdn = s[:kdn]
          @org_id = s[:org_id]
        end
      end
    else
      FileUtils.mkdir_p(@identity_dir)
    end
  end

  def gen_csr
    # in case of bad parameters for csr creation... we could call this function several times...

    # generate key is not already created... do NOT delete... ever!
    if !has_key?
      EZSSL.gen_csr_key(@key_file_path)
    end
 
    # generate csr is not already created... recreate only if activation is cancelled
    if !has_csr?
      EZSSL.gen_csr(@csr, @csr_file_path, @key_file_path)
    end

    @has_csr = true
  end

  def save_id_data
    File.open(@id_data_file_path, "w") do |f|
      d = {
        :admin_name => @admin_name, 
        :admin_email => @admin_email,
        :kdn => @kdn,
        :org_id => @org_id
      }
      YAML.dump(d, f)
    end
  end

  public

  attr_reader :id_name, :admin_name, :admin_email

  # Returns true if the object has enough data to produce a CSR.
  def has_csr_data?
    return (!country.nil? and !state.nil? and !location.nil? and !org.nil? and !domain.nil?)
  end

  def has_key?   
    return File.exists?(@key_file_path)
  end

  def has_csr?   
    return File.exists?(@csr_file_path)
  end

  def del_csr
    FileUtils.rm_f(@csr_file_path)
  end

  def has_cert?
      return File.exists?(@cert_file_path)
  end

  def country
    return @csr.country
  end

  def org_id
    return @org_id
  end

  def org_id=(val)
    @org_id = val
    save_id_data
  end

  def kdn
    return @kdn
  end

  def kdn=(val)
    @kdn = val
    save_id_data
  end

  def admin_name=(val)
    @admin_name = val
    save_id_data
  end

  def admin_email=(val)
    @admin_email = val
    save_id_data
  end

  def country=(val)
    #if !has_csr?
      @csr.country = val
      @csr.save_csr_data(@csr_data_file_path)
    #else
    #  raise ActivatorIdentityException.new("object read-only")
    #end
  end

   def state
    return @csr.state
  end

  def state=(val)
    #if !has_csr?
      @csr.state = val
      @csr.save_csr_data(@csr_data_file_path)
    #else
    #  raise ActivatorIdentityException.new("object read-only")
    #end
  end

  def location
    return @csr.location
  end

  def location=(val)
    #if !has_csr?
      @csr.location = val
      @csr.save_csr_data(@csr_data_file_path)
    #else
    #  raise ActivatorIdentityException.new("object read-only")
    #end
  end

  def org
    return @csr.org
  end

  def org=(val)
    #if !has_csr?
      @csr.org = val
      @csr.save_csr_data(@csr_data_file_path)
    #else
    #  raise ActivatorIdentityException.new("object read-only")
    #end
  end

  def org_unit
    return @csr.org_unit
  end

  def org_unit=(val)
    #if !has_csr?
      @csr.org_unit = val
      @csr.save_csr_data(@csr_data_file_path)
    #else
    #  raise ActivatorIdentityException.new("object read-only")
    #end
  end

  def domain
    return @csr.domain
  end

  def domain=(val)
    #if !has_csr?
      @csr.domain = val
      @csr.save_csr_data(@csr_data_file_path)
    #else
    #  raise ActivatorIdentityException.new("object read-only")
    #end
  end

  def email
    return @csr.email
  end

  def email=(val)
    #if !has_csr?
      @csr.email = val
      @csr.save_csr_data(@csr_data_file_path)
    #else
    #  raise ActivatorIdentityException.new("object read-only")
    #end
  end

  # Return the CSR file content.
  def get_csr
    # No op if its already done.
    gen_csr
    
    # Open the CSR file, which should exists after gen_csr.
    csr_str = ""
    File.open(@csr_file_path, "r") do |f|
      csr_str = f.read
    end

    return csr_str
  end

  # Once the CSR has been signed, call this method to save certificate
  # and set the identity has asserted.
  def set_cert(cert_str)
    #if !has_cert?
      File.open(@cert_file_path, "w") do |f|
        f.write(cert_str)
      end

      # Do some sanity checks on the certificate
      begin
        # Check the certificate
        if !check_cert then
          FileUtils.rm_f(@cert_file_path)
          raise ActivatorIdentityCertException.new(is_invalid = true, is_incorrect = true)
        end

        # Check if the certificate matches the CSR content.
        if !check_cert_key_match_csr_key then
          FileUtils.rm_f(@cert_file_path)
          raise ActivatorIdentityCertException.new(is_invalid = false, is_incorrect = true)
        end
       
      rescue Exception => ex
        # This makes sure we can restart if there is an unknown exception.
        FileUtils.rm_f(@cert_file_path)
        raise ex
      end

    #else
    #  raise ActivatorIdentityException.new("object read-only")
    #end
  end  

  # Return the certificate has a string.
  def get_cert
    cert_str = ""
    
    File.open(@cert_file_path, "r") do |f|
      cert_str = f.read
    end

    return cert_str
  end

  # Return the path to the certificate file.
  def get_cert_path
    if !has_cert?
      return nil
    end

    return @cert_file_path
  end

  # Return the path to the key file.
  def get_key_path
    # Generate the CSR if that wasn't already done.
    if !has_csr?
      gen_csr
    end
    
    return @key_file_path
  end

  # Return the path to the CSR file.
  def get_csr_path
    # Generate the CSR if that wasn't already done.
    if !has_csr?
      gen_csr
    end

    return @csr_file_path
  end

  # Reset the identity.  Removes all the file in the identity
  # directory.
  def reset
    if File.exists?(@identity_dir) and File.directory?(@identity_dir)

      @files_to_clean.each do |f|
        FileUtils.rm_f(f)
      end
      
      FileUtils.mkdir_p(@identity_dir)

      @csr = EZSSL_CSR.new
    end
  end

  # Format the object as string.
  def to_s
    s = "Name: #{@id_name}, "
    s += "Country: #{self.country}, "
    s += "State: #{self.state}, "
    s += "Loc: #{self.location}, "
    s += "Org: #{self.org}, "
    s += "Org Unit: #{self.org_unit}, "
    s += "Domain: #{self.domain}, "
    s += "Email: #{self.email}"
    return s
  end

  def ==(val)
    if val.class != ActivatorIdentity 
      return false
    end
    b_country = (self.country = val.country)
    b_state = (self.state = val.state)
    b_location = (self.location = val.location)
    b_org = (self.org = val.org)
    b_org_unit = (self.org_unit = val.org_unit)
    b_domain = (self.domain = val.domain)
    b_email = (self.email = val.email)
    
    b_country and b_state and b_location and b_org and b_org_unit and b_domain and b_email
  end
end 
