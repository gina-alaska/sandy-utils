#!/usr/bin/env ruby
# RTSPS helper..

ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('../..', __FILE__), 'Gemfile')
require 'bundler/setup'
require 'fileutils'
require_relative '../lib/processing_framework'

class DMSPL0Clamp <  ProcessingFramework::CommandLineHelper
  @description = 'This tool processes DMSP data to L0'
  @config = ProcessingFramework::ConfigLoader.default_path(__FILE__)

  option ['-c', '--config'], 'config', "The config file. Using #{@config} as the default.", default: @config
  option ['-i', '--input'], 'input', 'The input file. ', required: true

  def execute
    conf = ProcessingFramework::ConfigLoader.new(__FILE__)

    output = "#{outdir}"
    outdir += '/' + basename if basename
    basename = File.basename(input) unless basename

    platform =  basename.split('.').first

    working_dir = "#{tempdir}/#{basename}"
    begin
    	# make temp space
    	FileUtils.rm_r(working_dir) if (File.exist?(working_dir))
    	FileUtils.mkdir(working_dir)
    	FileUtils.cd(working_dir) do
      		sourcefile = File.basename(input)
      		FileUtils.cp(input, sourcefile)
      		sourcefile = ProcessingFramework::CompressHelper.uncompress(sourcefile)
      		tm =  DateTime.strptime(sourcefile.split('.')[1, 2].join('.'), '%y%j.%H%M%S')

      		command = "rtdin #{conf['opts']} tape_device=./#{sourcefile} pass_date=#{tm.strftime("%Y.%j")} pass_time=#{tm.strftime("%H:%M:%S")} satellite=f-#{sourcefile.split(".").first[1,2]}  ."
      		ProcessingFramework::ShellOutHelper.run_shell(". #{conf['terascan_driver']} ;  #{command}")
      		conf["save"].each do |i|
			Dir.glob(i).each do |x|
				puts "INFO: Copying #{x} to #{output}"
        			FileUtils.cp(x, output)
			end
      		end
    		FileUtils.rm_r(working_dir)
	end
     rescue RuntimeError => e
       puts "Error: #{e.to_s}"
       FileUtils.rm_r(working_dir) if (File.exist?(working_dir))
       exit(-1)
    end
  end
end

DMSPL0Clamp.run
