#!/usr/bin/env ruby
ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('../..', __FILE__), 'Gemfile')
require 'bundler/setup'
require 'fileutils'
require_relative '../lib/processing_framework'

class SnppEDRClamp <  ProcessingFramework::CommandLineHelper
  banner 'This tool does EDR processing for SNPP.'
  default_config 'viirs_edr'

  option ['-p', '--processors'], 'processors', 'The number of processors to use for processing.',  environment_variable: 'PROCESSING_NUMBER_OF_CPUS', default: 1

  parameter "INPUT", 'The input directory'
  parameter 'OUTPUT', 'The output directory'

  def execute
    mode = 'default'  # TODO: Refactor yml to not require mode
    exit_with_error("Unknown/unconfigured mode #{mode}", 19) unless conf['configs'][mode]
    processing_cfg = conf['configs'][mode]

    basename = File.basename(inputdir) unless basename
    working_dir = "#{tempdir}/#{basename}"

    inside(working_dir) do
      command = ". #{conf['env']} ; #{processing_cfg['driver']} -p #{processors} #{processing_cfg['options']} -i #{input}"
      shell_out!(command)

      copy_output(output)
    end
  end
end

SnppEDRClamp.run
