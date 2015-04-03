#!/usr/bin/env ruby
# Tool to generate geotif stuff for viirs
#
# for more info see: viirs_geotif.rb --help

ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('../..', __FILE__), 'Gemfile')
require 'bundler/setup'
require 'fileutils'
require_relative '../lib/processing_framework'

class ViirsGeotifClamp <  ProcessingFramework::CommandLineHelper
  @description = 'This tool takes VIIRS data and makes geotifs .'
  @config = ProcessingFramework::ConfigLoader.default_path(__FILE__)
  @conf = ProcessingFramework::ConfigLoader.new(__FILE__)

  option ['-c', '--config'], 'config', "The config file. Using #{@config} as the default.", default: @config
  option ['-i', '--inputdir'], 'inputdir', 'The input directory. ', required: true
  option ['-m', '--mode'], 'mode', "The mode to use #{@conf['configs'].keys.join(',')}.", default: 'default'
  option ['-p', '--processors'], 'processors', 'The number of processors to use for processing.',  environment_variable: 'PROCESSING_NUMBER_OF_CPUS', default: @conf['limits']['processor']

  def execute
    conf = ProcessingFramework::ConfigLoader.new(__FILE__)

    output = "#{outdir}"
    outdir += '/' + basename if basename
    basename = File.basename(inputdir) unless basename

    # check mode
    fail "Unknown/unconfigured mode #{mode}" unless conf['configs'][mode]
    processing_cfg = conf['configs']["#{mode}"]

    working_dir = "#{tempdir}/#{basename}"

    begin
     # make temp space
     FileUtils.rm_r(working_dir) if (File.exist?(working_dir))
     FileUtils.mkdir(working_dir)

     FileUtils.cd(working_dir) do
       #unless (ProcessingFramework::ShellOutHelper.run_shell(command))
	generate_300(processing_cfg)
     end
     FileUtils.rm_r(working_dir)
   rescue RuntimeError => e
     puts "Error: #{e.to_s}"
     FileUtils.rm_r(working_dir) if (File.exist?(working_dir))
     exit(-1)
   end
  end


  def generate_300(cfg)

  end
  def generate_600(cfg)
  end

  def get_grid_path(cfg)
	 File.join(File.expand_path('../..', __FILE__), cfg["grid_file"])
  end
end

ViirsGeotifClamp.run
