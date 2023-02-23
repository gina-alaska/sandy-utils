#!/usr/bin/env ruby
# SDR processing tool..
# Run like:
# /snpp_sdr.rb --inputdir /hub/raid/jcable/sandy/source/npp_test/ -m viirs -p 2 -o /hub/raid/jcable/sandy/output/test_viirs/ -t /hub/raid/jcable/sandy/temp/

ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('../..', __FILE__), 'Gemfile')
require 'bundler/setup'
require 'fileutils'
require_relative '../lib/processing_framework'

class SnppViirsSdrClamp <  ProcessingFramework::CommandLineHelper
  default_config 'snpp_sdr'
  banner 'This tool does SDR processing for SNPP.'

  option ['-m', '--mode'], 'mode', "The SDR to process, valid options are viirs, cris, atms.", default: 'viirs'
  option ['-p', '--processors'], 'processors', 'The number of processors to use for processing.',  environment_variable: 'PROCESSING_NUMBER_OF_CPUS', default: 1

  parameter "INPUT", "Input directory"
  parameter "OUTPUT", "Output directory"

  def execute
    exit_with_error("Unknown/unconfigured mode: #{mode}", 19) unless conf['configs'][mode]

    basename = File.basename(input) unless basename

    working_dir = "#{tempdir}/#{basename}"
    inside(working_dir) do
      processing_cfg = conf['configs'][mode]

      input_file = if File.exist?(input) && !File.directory?(input)
                     input
                   else
                     Dir.glob(File.join(input, processing_cfg['rdr_glob'])).first
                   end
    
      unless input_file
        puts("ERROR: RDR is missing for #{processing_cfg['rdr_glob']}!")
        return
      end

      command = ". #{conf['env']} ; #{processing_cfg['driver']} -p #{processors} #{processing_cfg['options']}  #{input_file}"
      result = shell_out!(command)

      copy_output(output, '*.h5')
    end
  end
end

SnppViirsSdrClamp.run
