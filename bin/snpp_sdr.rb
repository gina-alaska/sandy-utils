#!/usr/bin/env ruby
# SDR processing tool..
# Run like: 
# /snpp_sdr.rb --inputdir /hub/raid/jcable/sandy/source/npp_test/ -m viirs -p 2 -o /hub/raid/jcable/sandy/output/test_viirs/ -t /hub/raid/jcable/sandy/temp/

require "fileutils"
require_relative "../lib/processing_framework"


class SnppViirsSdrClamp <  ProcessingFramework::CommandLineHelper

  @description = "This tool does SDR processing for SNPP."
  @config = ProcessingFramework::ConfigLoader.default_path(__FILE__)
  @conf = ProcessingFramework::ConfigLoader.new(__FILE__)

  option ["-c", "--config"], "config", "The config file. Using #{@config} as the default.", :default => @config
  option ["-i", "--inputdir"], "inputdir", "The input directory. ", :required => true
  option ["-m", "--mode"], "mode", "The SDR to process, valid options are #{@conf["configs"].keys.join(",")}.", :default => "viirs"
  option ["-p", "--processors"], "processors", "The number of processors to use for processing.",  :environment_variable => "PROCESSING_NUMBER_OF_CPUS", :default => @conf["limits"]["processor"]

  def execute
	conf = ProcessingFramework::ConfigLoader.new(__FILE__)

	output = "#{outdir}"
	outdir += "/" + basename if basename

	#check mode
     	raise "Unknown/unconfigured mode #{mode}" if !conf["configs"][mode]

	working_dir = "#{tempdir}/#{basename}"
     	begin
		#make temp space
		FileUtils.rm_r(working_dir) if (File.exists?(working_dir))
		FileUtils.mkdir(working_dir)

		processing_cfg = conf["configs"]["#{mode}"]

		FileUtils.cd(working_dir) do
			command = ". #{conf["env"]} ; #{processing_cfg["driver"]} -p #{processors} #{processing_cfg["options"]}  #{inputdir}/#{processing_cfg["rdr_glob"]}"
			raise "Processing failed." if !ProcessingFramework::ShellOutHelper.run_shell(command)
			#raise "Processing Failed" if (ProcessingFramework::ShellOutHelper.run_shell
			copy_output(output)
		end
		FileUtils.rm_r(working_dir)
	rescue RuntimeError => e
	      	puts ("Error: #{e.to_s}")
		FileUtils.rm_r(working_dir) if (File.exists?(working_dir))
		exit(-1)
	end
  end
end

SnppViirsSdrClamp.run
