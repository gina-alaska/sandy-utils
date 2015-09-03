#!/usr/bin/env ruby
ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('../..', __FILE__), 'Gemfile')
require 'bundler/setup'
require 'fileutils'
require_relative '../lib/processing_framework'

class SnppAwipsClamp <  ProcessingFramework::CommandLineHelper
  banner 'This tool takes VIIRS data and makes it AWIPS ready.'
  default_config 'viirs_awips'

  option ['-p', '--processors'], 'processors', 'The number of processors to use for processing.',  environment_variable: 'PROCESSING_NUMBER_OF_CPUS', default: 1

  parameter "INPUT", "The input directory"
  parameter "OUTPUT", "The output directory"

  def execute
    mode = 'default' #TODO:  Refactor yml to not require mode.
    exit_with_error("Unknown/unconfigured mode #{mode}", 19) unless conf['configs'][mode]

    basename = File.basename(input) unless basename
    @processing_cfg = conf['configs'][mode]

    working_dir = "#{tempdir}/#{basename}"
    inside(working_dir) do
      viirs2awips
      crefl2awips if conf['driver_crefl']
      Dir.glob(@processing_cfg['save']).each do |awips_file|
        gzip!(awips_file)
      end
      copy_output(output, @processing_cfg['save'])
    end
  end

  def viirs2awips
    command = [
      conf['driver'],
      "-d #{input}",
      @processing_cfg['options'],
      "-g #{@processing_cfg['grid']}",
      "--backend-configs #{get_config_item(@processing_cfg['p2g_config'])}"
    ].join(" ")
    shell_out!(command)
  end

  def crefl2awips
    command = [
      conf['driver_crefl'],
      "-d #{input}",
      @processing_cfg['options'],
      "-g #{@processing_cfg['grid']}",
      "-p #{@processing_cfg['crefl_bands']}",
      "--backend-configs #{get_config_item(@processing_cfg['p2g_config'])}"
    ].join(" ")
    shell_out!(command)
  end

  def get_config_item(item)
    File.join(File.expand_path('../../config', __FILE__), item)
  end


end

SnppAwipsClamp.run
