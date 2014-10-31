#very simple unit test for config loader

require_relative "../lib/processing_framework.rb"
require "test/unit"

class Waffle < ProcessingFramework::ConfigLoader
	def load(f)
		{ "test" => "this is a test"}
	end
end
 
class ConfigLoader < Test::Unit::TestCase
 
  def test_simple
    cfg = ProcessingFramework::ConfigLoader.new(__FILE__)
    assert_equal(cfg["test"], "this is a test")
  end

  def test_simple_expanded
    cfg = Waffle.new(__FILE__)
    assert_equal(cfg["test"], "this is a test")
  end

end
