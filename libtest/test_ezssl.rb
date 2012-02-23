require 'test/unit'

class TestEZSSL < Test::Unit::TestCase

  FileUtils.rm("/tmp/csr") if File.exists?("/tmp/csr")
  FileUtils.rm("/tmp/key") if File.exists?("/tmp/key")
  FileUtils.rm("/tmp/csr.bin") if File.exists?("/tmp/csr.bin")
  FileUtils.rm("/tmp/csr.out") if File.exists?("/tmp/csr.out")

  def set_dummy_csr(csr)
    csr.country = "CA"
    csr.state = "Quebec"
    csr.location = "Sherbrooke"
    csr.org = "Opersys"
    csr.org_unit = ""
    csr.domain = "teambox.co"
    csr.email = "karim.yaghmour@opersys.com"
  end

  # Test CSR creation, saving and loading.
  def test_csr
    c = EZSSL_CSR.new
    set_dummy_csr(c)

    c.save_csr_data("/tmp/csr_data")

    d = EZSSL_CSR.new
    d.load_csr_data("/tmp/csr_data")

    assert_equal(c, d, 'can reload CSR data and get CSR')
  end 

  # Test key generation
  def test_csr_key
    d = EZSSL_CSR.new()
    set_dummy_csr(d)

    EZSSL.gen_csr_key("/tmp/key")
    z = EZSSL.gen_csr(d, "/tmp/csr", "/tmp/key")

    assert_operator(0, :<, File.stat("/tmp/key").size, 'non-zero sized key file')
    assert_operator(0, :<, File.stat("/tmp/csr").size, 'non-zero sized CSR file')
  end

  # Test S/MIME encryption
  def test_smime_encrypt
    File.open("/tmp/data", "w") do |f|
      f.write("blarg")
    end
    FileUtils.rm("/tmp/data.bin") if File.exists?("/tmp/data.bin")
    
    EZSSL.smime_encrypt("/usr/share/teambox-acttools/teambox_kps_install_cert.pem",
                        "/tmp/data",
                        "/tmp/data.bin")

    assert_operator(0, :<, File.stat("/tmp/data.bin").size, 'non-zero encryption result')
  end

  # Test S/MIME decryption.
  def test_smime_decrypt
    File.open("/tmp/data", "w") do |f|
      f.write("blarg")
    end
    FileUtils.rm("/tmp/data.bin") if File.exists?("/tmp/data.bin")
    FileUtils.rm("/tmp/data.out") if File.exists?("/tmp/data.out")

    EZSSL.smime_encrypt("/home/fdgonthier/keys/teambox_kps_install_cert.pem",
                        "/tmp/data",
                        "/tmp/data.bin")
    EZSSL.smime_decrypt("/home/fdgonthier/keys/teambox_kps_install_cert.pem",
                        "/home/fdgonthier/keys/teambox_kps_install_privkey.pem",
                        "/tmp/data.bin",
                        "/tmp/data.out")
    
    assert_operator(0, :<, File.stat("/tmp/data.out").size, 'non-zero decryption result')
    
    out = ""
    File.open("/tmp/data.out", "r") do |f|
      out = f.read
    end
    assert_equal("blarg", out)
  end

  # Signing.
  def test_smime_signing
    File.open("/tmp/data", "w") do |f|
      f.write("blarg")
    end
    FileUtils.rm("/tmp/data.sum") if File.exist?("/tmp/data.sum")

    EZSSL.digest("/tmp/data", "/tmp/data.sum")
    
    assert_operator(0, :<, File.stat("/tmp/data.sum").size, 'non-zero signing result')
  end

end
