# -*- coding: utf-8 -*-
require 'test/unit'
require 'activator_identity'
require 'fileutils'

class TestActivatorIdentity < Test::Unit::TestCase
  
  basedir = "/tmp/activation"
  ActivatorIdentity.basedir = basedir

  # Clear the base directory for testing.
  FileUtils.rm_r(basedir) if File.exists?(basedir)

  private

  def set_dummy_identity(id)
    id.country = "CA"
    id.state = "Québec"
    id.location = "Sherbrooke"
    id.org = "Opersys"
    id.org_unit = ""
    id.domain = "teambox.co"
    id.email = ""    
  end

  public

  def test_to_s
    b = ActivatorIdentity.new("test_to_s")
    b.reset
    set_dummy_identity(b)

    assert_equal("Name: test_to_s, Country: CA, State: Québec, Loc: Sherbrooke, Org: Opersys, Org Unit: , Domain: teambox.co, Email: ", "#{b}")
  end

  # Simple creation of identity.
  def test_simple_identity
    b = ActivatorIdentity.new("test_simple_identity")
    b.reset
    set_dummy_identity(b)
    assert_not_equal("", b.get_csr, 'has non-empty certificate request')
  end

  # Tests if the identity is readonly once we get a CSR from it.
  def test_readonly_identity
    b = ActivatorIdentity.new("test_readonly_identity")
    b.reset
    set_dummy_identity(b)

    assert_not_equal("", b.get_csr, 'has non-empty certificate request')

    assert_raise ActivatorIdentityException do
      b.country = "US"
    end
  end

  # Check certification of identity.
  def test_set_cert
    b = ActivatorIdentity.new("test_set_cert")
    b.reset
    set_dummy_identity(b)
    
    assert_not_equal("", b.get_csr, 'has non-empty certificate request')
    
    # Get the identity verified
    csr_path = b.get_csr_path    
    cert_path = "/tmp/cert.pem"
    system("(cd /home/fdgonthier/teambox_ca && ./signit #{csr_path} #{cert_path}) 2> /dev/null")
    
    assert_nothing_raised do
      File.open(cert_path, "r") do |f|
        b.set_cert(f.read)
      end
    end
    
    # Check the return code.
    assert_equal(0, $?, 'certificate has been produced')
    assert_equal(true, b.has_csr?, 'has certificate request')
    assert_equal(true, b.has_cert?, 'has certificate')
  end

  # Getting a list of identity.
  def test_identity_list
    b = ActivatorIdentity.new("test_identity_list")
    b.reset
    set_dummy_identity(b)

    id_list = ActivatorIdentity.list

    assert_not_nil(id_list)       
    assert_equal(2, id_list.length)

    z = nil
    id_list.each do |e|
      if e.id_name == 'test_identity_list'
        z = e
      end
    end

    assert_equal(b, z)
  end
end 
