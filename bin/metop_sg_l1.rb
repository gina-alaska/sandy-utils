#!/usr/bin/env ruby
# Metop-sga1 processing tool
# Run like:
# metop_sg_l1.rb -t /junk -m metimge -p 32 -o in out

ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('..', __dir__), 'Gemfile')
require 'bundler/setup'
require 'fileutils'
require_relative '../lib/processing_framework'

class MetSGSL1Clamp < ProcessingFramework::CommandLineHelper
  default_config 'metsg_l1'
  banner 'This tool does level1 and level0 processing for metop-sg.'

  option ['-m', '--mode'], 'mode', 'The sensor to process, valid options are metimage, mws', default: 'metimage'
  option ['-p', '--processors'], 'processors', 'The number of processors to use for processing.', environment_variable: 'PROCESSING_NUMBER_OF_CPUS', default: 32

  parameter 'INPUT', 'Input directory'
  parameter 'OUTPUT', 'Output directory'

  def execute
    exit_with_error("Unknown/unconfigured mode: #{mode}", 19) unless conf['configs'][mode]

    basename ||= File.basename(input)

    working_dir = "#{tempdir}/#{basename}"
    inside(working_dir) do
      processing_cfg = conf['configs'][mode]

      input_file = if File.exist?(input) && !File.directory?(input)
                     input
                   else
                     Dir.glob(File.join(input, processing_cfg['glob'])).first
                   end
      nav_file = Dir.glob(File.join(input, '*.NAVATT.dat')).first

      command = "#{processing_cfg['driver']} #{processing_cfg['options']} #{input_file} #{nav_file}"
      result = shell_out!(command)

      copy_output(output, 'output/*.nc')
    end
  end
end

MetSGSL1Clamp.run
