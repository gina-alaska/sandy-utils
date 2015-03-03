require_relative '../lib/processing_framework/gina_sat_utils'
require 'test/unit'

class ConfigTester < Test::Unit::TestCase
  def test_simple
    assert_equal(4, SimpleNumber.new(2).add(2))
    assert_equal(6, SimpleNumber.new(2).multiply(3))
  end
end
