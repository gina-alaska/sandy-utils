#!/usr/bin/env ruby
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
		sourcefile = ""

        	#make DATA (this is silly)
        	FileUtils.mkdir(working_dir + "/data/")
		FileUtils.cd(working_dir) do
			#This part is so we don't have to tweek the DATA part of the rtsps configs.
             		sourcefile = File.basename(input)
             		FileUtils.cp(input, sourcefile)
             		sourcefile = ProcessingFramework::CompressHelper.uncompress(sourcefile)
        	end
        	FileUtils.cd(working_dir + "/data/") do
			ProcessingFramework::ShellOutHelper.run_shell("#{conf["rtsps_driver"]} #{conf["configs"][platform]} ../#{sourcefile}")
		
			# Maybe should do something else, perhaps complain?
	    		FileUtils.mkdir(output)  if (!File.exists?(output)) 
			#copy output
            		Dir.glob("*").each do |x|
               			puts("INFO: Copying #{x} to #{output}")
               			FileUtils.cp(x, output)
            		end
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
