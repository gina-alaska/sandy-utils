#!/usr/bin/env ruby
# acspo processing for sst etc
# Run like:
# acspo_l2.rb -t temp -m viirs in out

ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('../..', __FILE__), 'Gemfile')
require 'bundler/setup'
require 'fileutils'
require_relative '../lib/processing_framework'

class AcspoL2Clamp <  ProcessingFramework::CommandLineHelper
  banner 'This tool does acspo processing generating sst etc'
  default_config 'acspo_l2'

  option ['-m', '--mode'], 'mode', 'mode', default: 'default'

  parameter 'INPUT', 'Input directory'
  parameter 'OUTPUT', 'Output directory'

  def execute
    exit_with_error("Unknown/unconfigured mode: #{mode}", 19) unless conf['configs'][mode]

    basename = File.basename(input) unless basename

    working_dir = "#{tempdir}/#{basename}"
    inside(working_dir) do
      processing_cfg = conf['configs'][mode]

      command = "#{processing_cfg['driver']} #{processing_cfg['options']} -b #{processing_cfg['bias']} -i #{input}"
      result = shell_out!(command)

      copy_output(output, processing_cfg['save'])
    end
  end
end

AcspoL2Clamp.run
