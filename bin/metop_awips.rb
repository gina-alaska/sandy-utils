#!/usr/bin/env ruby
ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('../..', __FILE__), 'Gemfile')
require 'bundler/setup'
require 'fileutils'
require_relative '../lib/processing_framework'

class MetopAwipsClamp <  ProcessingFramework::CommandLineHelper
  attr_reader :processing_cfg
  banner 'This tool takes MODIS data and makes it AWIPS ready.'
  default_config 'metop_awips'

  option ['-m', '--mode'], 'mode', 'The mode to use.', default: 'default'
  option ['-p', '--processors'], 'processors', 'The number of processors to use for processing.',  environment_variable: 'PROCESSING_NUMBER_OF_CPUS', default: 1
  option ['-s', '--save'], 'save_pattern', 'A regular expression for the items to save - that is what items generated should be saved.', default: '*'

  parameter 'INPUT', 'The input directory'
  parameter 'OUTPUT', 'The output directory'

  def execute
    @processing_cfg = conf['configs'][mode]
    exit_with_error("Unknown mode #{mode}", 19) if processing_cfg.nil?

    basename = File.basename(input) unless basename
    working_dir = "#{tempdir}/#{basename}"

    inside(working_dir) do
      avhrr2awips

      Dir.glob(processing_cfg['save']).each do |awips_file|
        gzip!(awips_file)
      end
      copy_output(output, processing_cfg['save'])
    end
  end

  def avhrr2awips
    command = [
      conf['driver'],
      "-d #{input}",
      processing_cfg['options'],
      "-g #{processing_cfg['grid']}",
      "--backend-configs #{get_config_item(processing_cfg['p2g_config'])}"
    ].join(' ')
    shell_out!(command)
  end

  # returns path to extras in config
  def get_config_item(item)
    File.join(File.expand_path('../../config', __FILE__), item)
  end
end

MetopAwipsClamp.run