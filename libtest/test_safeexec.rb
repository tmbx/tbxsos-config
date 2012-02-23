require 'test/unit'
require 'safeexec'

class TestSafeExec < Test::Unit::TestCase
  include SafeExec
  
  # Test safeexec.
  def test_safeexec_good
    ls_in, ls_out, ls_err = KPopen3.new("/bin/ls /tmp").pipes
    ls_in.close

    str_out, str_err = SafeExec.empty_pipes([ls_out, ls_err])

    # Got stdout.
    assert_operator(0, :<, str_out.size)
  end

  # Test safeexec
  def test_safeexec_bad
    ls_in, ls_out, ls_err = KPopen3.new("/bin/ls /usr/blarg/blarg").pipes
    ls_in.close

    str_out, str_err = SafeExec.empty_pipes([ls_out, ls_err])

    # Got stderr.
    assert_operator(0, :<, str_err.size)
  end
end
