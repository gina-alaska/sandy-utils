#!/usr/bin/env ruby
ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('../..', __FILE__), 'Gemfile')
require 'bundler/setup'
require 'fileutils'
require_relative '../lib/processing_framework'

class OmpsEDRClamp <  ProcessingFramework::CommandLineHelper
  banner 'This tool does EDR processing for OMPS.'
  default_config 'omps_edr'

  option ['-p', '--processors'], 'processors', 'The number of processors to use for processing.',  environment_variable: 'PROCESSING_NUMBER_OF_CPUS', default: 1

  parameter "INPUT", 'The input directory'
  parameter 'OUTPUT', 'The output directory'

  def execute

    basename = File.basename(input) unless basename
    working_dir = "#{tempdir}/#{basename}"

    inside(working_dir) do
      command = " #{conf['config']['omps']['driver']} #{conf['config']['omps']['options']} #{input}"
      shell_out!(command, clean_environment: true)
      command = " #{conf['config']['omps_so2']['driver']} #{conf['config']['omps_so2']['options']} #{input}"
      shell_out!(command, clean_environment: true)
      copy_output(output, '*.nc')
    end
  end
end

OmpsEDRClamp.run
