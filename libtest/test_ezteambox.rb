require 'test/unit'

class TestEZTeambox < Test::Unit::TestCase

  # Test key generation.
  def test_keys
    Dir.glob("/tmp/testezteambox.*") do |f|
      FileUtils.rm(f)
    end

    EZTeambox.gen_keys(:both, 10000, "/tmp/testezteambox", "Blarg")

    assert(File.exists?("/tmp/testezteambox.enc.skey"), 'has secret encryption key')
    assert(File.exists?("/tmp/testezteambox.enc.pkey"), 'has public encryption key')
    assert(File.exists?("/tmp/testezteambox.sig.skey"), 'has secret signature key')
    assert(File.exists?("/tmp/testezteambox.sig.pkey"), 'has public signature key')
  end

end
