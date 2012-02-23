require 'test/unit'
require 'activator_keys'

class TestActivatorKeys < Test::Unit::TestCase
  
  ActivatorKeys.basedir = "/tmp/activation"

  def test_simple_keys
    a = ActivatorKeys.new("blarg")
    a.reset

    assert_equal(false, a.has_complete_set?, 'not a complete set')
  end

  def test_renumber_keys
    a = ActivatorKeys.new("blarg")
    a.reset

    a.set_keyid(10)
    assert_equal(true, a.has_enc_skey, 'has encryption public key')
    assert_equal(true, a.has_enc_pkey, 'has encryption secret key')

    a.reset

    assert_equal(false, a.has_enc_skey, 'encryption private key gone')
    assert_equal(false, a.has_enc_pkey, 'encryption public key gone')
  end

end
