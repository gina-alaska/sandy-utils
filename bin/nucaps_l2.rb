#!/usr/bin/env ruby
ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('../..', __FILE__), 'Gemfile')
require 'bundler/setup'
require 'fileutils'
require_relative '../lib/processing_framework'

class NucapsL2Clamp <  ProcessingFramework::CommandLineHelper
  banner 'This tool takes CRIS and ATMS data and makes NUCAPS L2 products.'
  default_config 'nucaps_l2'

  option ['-p', '--processors'], 'processors', 'The number of processors to use for processing.',  environment_variable: 'PROCESSING_NUMBER_OF_CPUS', default: 1
  option ['-m', '--mode'], 'mode', 'The mode', default: 'npp'

  parameter 'INPUT', 'The input directory'
  parameter 'OUTPUT', 'The output directory'

  def execute
    exit_with_error("Unknown/unconfigured mode #{mode}", 19) unless conf['configs'][mode]

    basename = File.basename(input) unless basename
    @processing_cfg = conf['configs'][mode]

    working_dir = "#{tempdir}/#{basename}"
    inside(working_dir) do
      shell_out(@processing_cfg['driver'] + " -i #{input} ")
      copy_output(output, @processing_cfg['save'])
    end
  end
end

NucapsL2Clamp.run
