##
# RTSPS helper..

require_relative "../lib/processing_framework"

class RtstpsClamp <  ProcessingFramework::CommandLineHelper 

  @description = "This tool does CCSDS unpacking using Rtstps for SNPP, AQUA, and TERRA."
  @config = ProcessingFramework::ConfigLoader.default_path(__FILE__)
  
  option ["-c", "--config"], "config", "The config file. Using #{@config} as the default.", :default => @config
  option ["-i", "--input"], "input", "The input file. If --basename is included, it is appended to this.", :required => true

  def execute 
	conf = ProcessingFramework::ConfigLoader.new(__FILE__)
  end

end

RtstpsClamp.run
