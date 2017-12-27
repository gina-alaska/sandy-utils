#!/usr/bin/env ruby
# SDR processing tool..
# Run like:
# /snpp_sdr.rb --inputdir /hub/raid/jcable/sandy/source/npp_test/ -m viirs -p 2 -o /hub/raid/jcable/sandy/output/test_viirs/ -t /hub/raid/jcable/sandy/temp/

ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('../..', __FILE__), 'Gemfile')
require 'bundler/setup'
require 'fileutils'
require_relative '../lib/processing_framework'

class NucapsSdrClamp <  ProcessingFramework::CommandLineHelper
  default_config 'nucaps_sdr'
  banner 'This tool does SDR processing for SNPP/NOAA20 in a combined manner for nucaps.'

  option ['-m', '--mode'], 'mode', 'The SDR to process, valid options are nucaps.', default: 'nucaps'
  option ['-p', '--processors'], 'processors', 'The number of processors to use for processing.',  environment_variable: 'PROCESSING_NUMBER_OF_CPUS', default: 1

  parameter 'INPUT', 'Input directory'
  parameter 'OUTPUT', 'Output directory'

  def execute
    exit_with_error("Unknown/unconfigured mode: #{mode}", 19) unless conf['configs'][mode]

    basename = File.basename(input) unless basename

    working_dir = "#{tempdir}/#{basename}"
    inside(working_dir) do
      processing_cfg = conf['configs'][mode]
      bin_dir = File.dirname(__FILE__) + '/'
      processing_cfg['tasks'].each do |task|
        shell_out!(bin_dir + task  + "-t #{tempdir}/nucaps #{input} #{output}")
      end
    end
  end
end

NucapsSdrClamp.run
