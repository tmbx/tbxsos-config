# -*- coding: utf-8 -*-
require 'test/unit'
require 'activator_identity'
require 'activator_keys'
require 'activator_kar'

class TestActivatorKAR < Test::Unit::TestCase

  ActivatorKeys.basedir = "/tmp/activation"
  ActivatorIdentity.basedir = "/tmp/activation"
  ActivatorKAR.teambox_ssl_cert_path = "/home/fdgonthier/teambox_ca/trusted_ca/teambox_kar_sign_cert.pem"
  ActivatorKAR.basedir = "/tmp/activation"

  def set_dummy_identity(id)
    id.country = "CA"
    id.state = "Québec"
    id.location = "Sherbrooke"
    id.org = "Opersys"
    id.org_unit = ""
    id.domain = "teambox.co"
    id.email = ""    
  end

  # Test simple KAR generation.
  def test_simple_kar
    # Clear the key set
    keys = ActivatorKeys.new("blarg")
    keys.reset

    # Clear the identity
    id = ActivatorIdentity.new("blarg")
    id.reset
    set_dummy_identity(id)
    
    # Create the KAR.
    kar = ActivatorKAR.new("blarg")

    # Get the identity verified
    csr_path = id.get_csr_path    
    cert_path = "/tmp/cert.pem"
    system("(cd /home/fdgonthier/teambox_ca && ./signit #{csr_path} #{cert_path}) 2> /dev/null")

    assert_nothing_raised do
      File.open(cert_path, "r") do |f|
        id.set_cert(f.read)
      end
    end

    assert_not_equal("", kar.get_kar(id, keys))
  end

  # Test KAR generation with parent identity.
  def test_with_parent
    id = ActivatorIdentity.new("blarg")
    id.reset
    set_dummy_identity(id)

    keys = ActivatorKeys.new("blarg")
    keys.reset

    # Get the identity verified
    csr_path = id.get_csr_path    
    cert_path = "/tmp/cert.pem"
    system("(cd /home/fdgonthier/teambox_ca && ./signit #{csr_path} #{cert_path}) 2> /dev/null")

    assert_nothing_raised do
      File.open(cert_path, "r") do |f|
        id.set_cert(f.read)
      end
    end

    # Now create the KAR.
    kar = ActivatorKAR.new("blarg2")
    
    assert_not_equal("", kar.get_kar(id, keys))
  end

end
