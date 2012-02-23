# Quick and dirty set of OpenSSL functions which call the openssl binary.
# - S/MIME decrypt/encrypt operations.
# - CSR generation

require 'tempfile'
require 'fileutils'
require 'fileasserts'
require 'safeexec'
require 'yaml'

class EZSSLException < Exception
  def initialize(err)
    super(err)
  end
end

class EZSSL_CSR
  private
  
  # Check if we have at least the required fields.
  def check()
    if @csr_data[:country] == "" 
      raise EZSSLException.new("'Country' is missing") 
    end
    if @csr_data[:state] == "" 
      raise EZSSLException.new("'State' is missing") 
    end
    if @csr_data[:location] == "" 
      raise EZSSLException.new("'Location' is missing") 
    end
    if @csr_data[:org] == "" 
      raise EZSSLException.new("'Organization' is missing") 
    end
    if @csr_data[:domain] == "" 
      raise EZSSLException.new("'Domain' is missing") 
    end
  end

  public

  # Lame getter/setters setting/getting data from the @csr_data hash.

  def country 
    return @csr_data[:country] 
  end
  
  def country=(val)
    @csr_data[:country] = val
  end

  def state
    return @csr_data[:state]
  end

  def state=(val)
    @csr_data[:state] = val
  end

  def location
    return @csr_data[:location]
  end

  def location=(val)
    @csr_data[:location] = val
  end

  def org
    return @csr_data[:org]
  end

  def org=(val)
    @csr_data[:org] = val
  end

  def org_unit
    return @csr_data[:org_unit]
  end

  def org_unit=(val)
    @csr_data[:org_unit] = val
  end

  def domain
    return @csr_data[:domain]
  end

  def domain=(val)
    @csr_data[:domain] = val
  end

  def email
    return @csr_data[:email]
  end

  def email=(val)
    @csr_data[:email] = val
  end

  # Save the CSR data file.
  def save_csr_data(csr_data_file)
    File.open(csr_data_file, "w") do |f|
      YAML.dump(@csr_data, f)
    end
  end

  # Load the CSR data.
  def load_csr_data(csr_data_file)
    File.open(csr_data_file, "r") do |f|
      @csr_data = YAML.load(f)
    end
  end

  # Save the CSR in a temporary file.
  def save
    check

    t = Tempfile.new("tmp")
    t.write "[req]\n"
    t.write "distinguished_name = req_distinguished_name\n"
    t.write "prompt = no\n"
    t.write "\n"
    t.write "[req_distinguished_name]\n"
    t.write "C = #{@csr_data[:country]}\n"
    t.write "ST = #{@csr_data[:state]}\n"
    t.write "L = #{@csr_data[:location]}\n"
    t.write "O = #{@csr_data[:org]}\n"
    if @csr_data[:org_unit] and @csr_data[:org_unit] != ""
      t.write "OU = #{@csr_data[:org_unit]}\n"
    end
    t.write "CN = #{@csr_data[:domain]}\n"
    if @csr_data[:email] and @csr_data[:email] != ""
      t.write "emailAddress = #{@csr_data[:email]}\n"
    end
    t.close

    return t.path
  end

  def ==(val)
    if val.class != EZSSL_CSR
      return false
    end

    b_country = (self.country == val.country)
    b_state = (self.state == val.state)
    b_loc = (self.location == val.location)
    b_org = (self.org == val.org)
    b_org_unit = (self.org_unit = val.org_unit)
    b_domain = (self.domain == val.domain)
    b_email = (self.email == val.email)
    
    b_country and b_state and b_loc and b_org and b_org_unit and b_domain and b_email
  end

  def initialize
    @csr_data = {}
  end
end

class EZSSL
  public

  include FileAsserts
  include SafeExec

  attr_reader :infile, :outfile
  attr_writer :infile, :outfile

  # Returns a message digest in a file.  Preset to SHA-2 for now.
  def EZSSL.digest(in_file_path, out_file_path) 
    FileAsserts.assert_file_readable(in_file_path)
    FileAsserts.assert_file_creatable(out_file_path)

    in_file = File.open(in_file_path, "r")
    in_file_content = in_file.read

    begin
      po = KPopen3.new("sha256sum #{in_file_path}")
      os_in, os_out, os_err = po.pipes
      os_in.close

      out_str, err_str = SafeExec.empty_pipes([os_out, os_err])
    ensure
      po.close
    end

    if $? != 0
      raise EZSSLException.new("sha256sum error: #{err_str.strip}")
    else
      begin
        out_file = File.open(out_file_path, "w")
        out_file.print out_str.strip.split[0] + "\n"
      ensure
        out_file.close
      end
    end
  end

  # Generate a KEY for generating CSR later
  def EZSSL.gen_csr_key(csr_key_file_path)
    # Don't overwrite the path path.
    FileAsserts.assert_file_creatable(csr_key_file_path)

    begin
      po = KPopen3.new("openssl genrsa -out #{csr_key_file_path} 1024")
      os_in, os_out, os_err = po.pipes
      os_in.close
      out_str, err_str = SafeExec.empty_pipes([os_out, os_err])

      csr_key_exists = File.exists?(csr_key_file_path)
    ensure
      po.close
    end

    if $? != 0
      if csr_key_exists
        FileUtils.rm(csr_key_file_path)
      end

      raise EZSSLException.new("OpenSSL error: #{err_str.strip}")
    end
  end

  # Generate a CSR request.
  def EZSSL.gen_csr(csr, csr_file_path, key_file_path)
    path = csr.save

    # Don't overwrite the two provided paths.
    FileAsserts.assert_file_creatable(csr_file_path)

    begin
      po = KPopen3.new("openssl req -nodes -new " +
                       "-config #{path} " +
                       "-key #{key_file_path} " +
                       "-out #{csr_file_path} " +
                       "-days 9999")
      os_in, os_out, os_err = po.pipes
      os_in.close
      out_str, err_str = SafeExec.empty_pipes([os_out, os_err])

      csr_exists = File.exists?(csr_file_path)
    ensure
      po.close
    end

    if $? != 0
      # Remove the file that OpenSSL managed to create if there is
      # any.
      if csr_exists
        FileUtils.rm(csr_file_path)
      end

      raise EZSSLException.new("OpenSSL error: #{err_str.strip}")
    end
  end

  # Generate a CSR request. !!!!OLD VERSION!!!!
  def EZSSL.gen_csrOLD(csr, csr_file_path, key_file_path)
    path = csr.save

    # Don't overwrite the two provided paths.
    FileAsserts.assert_file_creatable(csr_file_path)
    FileAsserts.assert_file_creatable(key_file_path)

    begin
      po = KPopen3.new("openssl req -nodes -new " +
                       "-config #{path} " +
                       "-keyout #{key_file_path} " +
                       "-out #{csr_file_path} " +
                       "-days 9999")
      os_in, os_out, os_err = po.pipes
      os_in.close
      out_str, err_str = SafeExec.empty_pipes([os_out, os_err])

      csr_exists = File.exists?(csr_file_path)
      key_exists = File.exists?(key_file_path)
    ensure
      po.close
    end

    if $? != 0
      # Remove the file that OpenSSL managed to create if there is
      # any.
      if csr_exists
        FileUtils.rm(csr_file_path)
      end

      if key_exists
        FileUtils.rm(key_file_path)
      end

      raise EZSSLException.new("OpenSSL error: #{err_str.strip}")
    end
  end


  # Check CERT.
  def EZSSL.check_cert(key_file_path, crt_file_path, csr_file_path)

    # Don't overwrite the two provided paths.
    FileAsserts.assert_file_readable(key_file_path)
    FileAsserts.assert_file_readable(crt_file_path)
    FileAsserts.assert_file_writable(csr_file_path)

    begin
      po = KPopen3.new("openssl x509" +
                       " -signkey #{key_file_path}" +
                       " -in #{crt_file_path}" +
                       " -x509toreq" +
                       " -out #{csr_file_path}")
      os_in, os_out, os_err = po.pipes
      os_in.close
      out_str, err_str = SafeExec.empty_pipes([os_out, os_err])
    ensure
      po.close
    end

    if $? == 0
      return true
    end

    return false
  end


  def EZSSL.smime_encrypt(recip_cert, input_file_path, output_file_path)
    FileAsserts.assert_file_readable(input_file_path)
    FileAsserts.assert_file_readable(recip_cert)
    FileAsserts.assert_file_creatable(output_file_path)
    
    begin
      po = KPopen3.new("openssl smime -encrypt " +
                       "-binary -outform pem -aes256 " +
                       "-in #{input_file_path} " +
                       "-out #{output_file_path} " +
                       "#{recip_cert}")
      os_in, os_out, os_err = po.pipes
      os_in.close
      out_str, err_str = SafeExec.empty_pipes([os_out, os_err])      
    ensure
      po.close
    end

    if $? != 0
      raise EZSSLException.new("OpenSSL error: #{err_str.strip}")
    end
  end

  def EZSSL.smime_decrypt(recip_cert, recip_key, input_file_path, output_file_path)
    FileAsserts.assert_file_readable(recip_cert)
    FileAsserts.assert_file_readable(recip_key)
    FileAsserts.assert_file_readable(input_file_path)
    FileAsserts.assert_file_creatable(output_file_path)

    begin
      po = KPopen3.new("openssl smime -decrypt " +
                       "-inform pem " + 
                       "-in #{input_file_path} " +
                       "-out #{output_file_path} " +
                       "-recip #{recip_cert} " + 
                       "-inkey #{recip_key}")
      os_in, os_out, os_err = po.pipes
      os_in.close
      out_str, err_str = SafeExec.empty_pipes([os_out, os_err])      
    ensure
      po.close
    end

    if $? != 0
      raise EZSSLException.new("OpenSSL error #{err_str.strip}")
    end
  end
end

