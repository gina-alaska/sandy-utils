#!/usr/bin/env ruby
# clavrx processing for cloud masks etc
# Run like:
# clavrx_l2.rb -t temp -m viirs in out

ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('../..', __FILE__), 'Gemfile')
require 'bundler/setup'
require 'fileutils'
require_relative '../lib/processing_framework'

class ClavrxL2Clamp <  ProcessingFramework::CommandLineHelper
  banner 'This tool does acspo processing generating sst etc'
  default_config 'clavrx_l2'

  option ['-m', '--mode'], 'mode', 'mode', default: 'default'

  parameter 'INPUT', 'Input directory'
  parameter 'OUTPUT', 'Output directory'

  def execute
    exit_with_error("Unknown/unconfigured mode: #{mode}", 19) unless conf['configs'][mode]

    basename = File.basename(input) unless basename

    working_dir = "#{tempdir}/#{basename}"
    inside(working_dir) do
      processing_cfg = conf['configs'][mode]

      command = "#{processing_cfg['driver']} #{processing_cfg['options']} #{input} ./work ./done"
      result = shell_out!(command,  clean_environment: true ))

      processing_cfg['save'].each do |save_glob|
         copy_output(output, save_glob)
      end
    end
  end
end

ClavrxL2Clamp.run
