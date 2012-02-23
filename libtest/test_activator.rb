# -*- coding: utf-8 -*-
require 'test/unit'
require 'activator'
require 'activator_identity'
require 'activator_keys'
require 'activator_kar'

class TestActivator < Test::Unit::TestCase

  Activator.basedir = "/tmp/activation"
  Activator.teambox_ssl_cert_path = "/home/fdgonthier/teambox_ca/trusted_ca/teambox_kar_sign_cert.pem"
  Activator.teambox_sig_pkey_path = "/usr/share/teambox-acttools/teambox_kps_email.sig.pkey"

  ActivatorIdentity.basedir = "/tmp/activation"
  ActivatorKeys.basedir = "/tmp/activation"

  # KAR generation.
  def test_activation_kar
    a = Activator.create_new

    # Make sure the activator is new.
    assert_equal(0, a.step)

    # Prepare the CSR.
    a.admin_name = "Karim Yaghmour"
    a.admin_email = "karim.yaghmour@opersys.com"
    
    a.country = "CA"
    a.state = "Québec"
    a.location = "Sherbrooke"
    a.org = "Opersys"
    a.org_unit = ""
    a.domain = "teambox.co"
    a.email = ""
    
    # Check if we can produce a CSR.
    assert_not_nil(a.get_csr, 'CSR generation')

    # Check that we can procude a KAR.
    assert_nil(a.get_kar, 'impossibility of KAR generation without certificate')

    # Get the identity verified
    i = ActivatorIdentity.new(a.name)
    csr_path = i.get_csr_path    
    cert_path = "/tmp/cert.pem"
    system("(cd /home/fdgonthier/teambox_ca && ./signit #{csr_path} #{cert_path}) 2> /dev/null")

    assert_nothing_raised do
      File.open(cert_path, "r") do |f|
        i.set_cert(f.read)
      end
    end

    # Retry getting the KAR.
    assert_not_nil(a.get_kar, 'KAR generation with certificate')
  end

end
