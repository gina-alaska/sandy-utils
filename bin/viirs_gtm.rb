#!/usr/bin/env ruby

ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('../..', __FILE__), 'Gemfile')
require 'bundler/setup'
require 'fileutils'
require_relative '../lib/processing_framework'

class SnppViirsGtmClamp <  ProcessingFramework::CommandLineHelper
  @description = 'This tool does GTM processing for VIIRS.'
  @config = ProcessingFramework::ConfigLoader.default_path(__FILE__)
  @conf = ProcessingFramework::ConfigLoader.new(__FILE__)

  option ['-c', '--config'], 'config', "The config file. Using #{@config} as the default.", default: @config
  option ['-i', '--inputdir'], 'inputdir', 'The input directory. ', required: true
  option ['-p', '--processors'], 'processors', 'The number of processors to use for processing.',  environment_variable: 'PROCESSING_NUMBER_OF_CPUS', default: @conf['limits']['processor']

  def execute
    conf = ProcessingFramework::ConfigLoader.new(__FILE__)

    basename = File.basename(inputdir) unless basename

    working_dir = "#{tempdir}/#{basename}"
    begin
      # make temp space
      FileUtils.rm_r(working_dir) if (File.exist?(working_dir))
      FileUtils.mkdir(working_dir)

      processing_cfg = conf['configs']["#{mode}"]

      FileUtils.cd(working_dir) do
        command = ". #{conf['env']} ; #{processing_cfg['driver']} -p #{processors} #{processing_cfg['options']}  #{inputdir}/#{processing_cfg['rdr_glob']}"
        fail 'Processing failed. GTM' unless ProcessingFramework::ShellOutHelper.run_shell(command)
        command = ". #{conf['env']} ; awips2_gtm_edr.sh -s KNES -r TIPB ."
        fail 'Processing failed. AWIPS Conversion' unless ProcessingFramework::ShellOutHelper.run_shell(command)

        copy_output(outdir)
      end
      FileUtils.rm_r(working_dir)
    rescue RuntimeError => e
      puts "Error: #{e.to_s}"
      FileUtils.rm_r(working_dir) if (File.exist?(working_dir))
      exit(-1)
    end
  end
end

SnppViirsGtmClamp.run
