require_relative '../lib/processing_framework.rb'
require 'test/unit'

class ConfigLoader < Test::Unit::TestCase
  def test_simple
    cfg = ProcessingFramework::ConfigLoader.new(__FILE__)
    assert_equal(cfg['test'], 'this is a test')
  end
end
