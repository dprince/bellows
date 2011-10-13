$:.unshift File.dirname(__FILE__)
require 'helper'

class UtilTest < Test::Unit::TestCase

  def test_short_spec
    assert_equal "123/123", Bellows::Util.short_spec("123/123/123")
  end

end
