#!/usr/bin/env ruby
# EDR processing tool..
# Run like:
# /snpp_edr.rb --inputdir /hub/raid/jcable/sandy/source/npp_test/ -m viirs -p 2 -o /hub/raid/jcable/sandy/output/test_viirs/ -t /hub/raid/jcable/sandy/temp/

ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('../..', __FILE__), 'Gemfile')
require 'bundler/setup'
require 'fileutils'
require_relative '../lib/processing_framework'

class SnppEDRClamp <  ProcessingFramework::CommandLineHelper
  @description = 'This tool does EDR processing for SNPP.'
  @config = ProcessingFramework::ConfigLoader.default_path(__FILE__)
  @conf = ProcessingFramework::ConfigLoader.new(__FILE__)

  option ['-c', '--config'], 'config', "The config file. Using #{@config} as the default.", default: @config
  option ['-i', '--inputdir'], 'inputdir', 'The input directory. ', required: true
  option ['-m', '--mode'], 'mode', "The SDR to process, valid options are #{@conf['configs'].keys.join(',')}.", default: 'viirs'
  option ['-p', '--processors'], 'processors', 'The number of processors to use for processing.',  environment_variable: 'PROCESSING_NUMBER_OF_CPUS', default: @conf['limits']['processor']

  def execute
    conf = ProcessingFramework::ConfigLoader.new(__FILE__)

    output = "#{outdir}"
    outdir += '/' + basename if basename
    basename = File.basename(inputdir) unless basename

    # check mode
    fail "Unknown/unconfigured mode #{mode}" unless conf['configs'][mode]

    working_dir = "#{tempdir}/#{basename}"
    begin
      # make temp space
      FileUtils.rm_r(working_dir) if File.exist?(working_dir)
      FileUtils.mkdir(working_dir)

      processing_cfg = conf['configs'][mode]

      FileUtils.cd(working_dir) do
        command = ". #{conf['env']} ; #{processing_cfg['driver']} -p #{processors} #{processing_cfg['options']} -i #{inputdir}"
        fail 'Processing failed.' unless ProcessingFramework::ShellOutHelper.run_shell(command, true)
        # raise "Processing Failed" if (ProcessingFramework::ShellOutHelper.run_shell
        copy_output(output)
      end
      FileUtils.rm_r(working_dir)
    rescue RuntimeError => e
      puts "Error: #{e.to_s}"
      FileUtils.rm_r(working_dir) if (File.exist?(working_dir))
      exit(-1)
    end
  end
end

SnppEDRClamp.run
