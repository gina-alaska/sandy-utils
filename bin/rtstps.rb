##
# RTSPS helper..

require "fileutils"
require_relative "../lib/processing_framework"

class RtstpsClamp <  ProcessingFramework::CommandLineHelper 

  @description = "This tool does CCSDS unpacking using Rtstps for SNPP, AQUA, and TERRA."
  @config = ProcessingFramework::ConfigLoader.default_path(__FILE__)
  
  option ["-c", "--config"], "config", "The config file. Using #{@config} as the default.", :default => @config
  option ["-i", "--input"], "input", "The input file. ", :required => true

  def execute 
	conf = ProcessingFramework::ConfigLoader.new(__FILE__)

	output = "#{outdir}" 
	outdir += "/" + basename if basename
	basename = File.basename(input) if !basename

	platform =  basename.split(".").first
	
		#check platofrm
	raise "Unknown/unconfigured platform #{platform}" if !conf["configs"][platform]
	
	working_dir = "#{tempdir}/#{basename}"
	begin
	
		#make temp space
		FileUtils.rm_r(working_dir) if (File.exists?(working_dir))
		FileUtils.mkdir(working_dir)

		FileUtils.cd(working_dir) do
			puts("Would do: #{conf["rtsps_driver"]} #{conf["configs"][platform]}")
		
			#check output here

			FileUtils.mkdir(output)  if (File.exists?(output))
			
			#copy output
		end

		FileUtils.rm_r(working_dir)

		
	rescue RuntimeError => e
		puts ("Error: #{e.to_s}")
		FileUtils.rm_r(working_dir) if (File.exists?(working_dir))
		
		exit(-1)
	end
  end

end

RtstpsClamp.run
