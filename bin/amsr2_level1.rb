#!/usr/bin/env ruby
# AMSR2 processing tool..
# Run like:
# /amsr2_level1.rb --inputdir /hub/raid/jcable/sandy/source/gcomw_test/ -m amsr2 -o /hub/raid/jcable/sandy/output/test_level1 -t /hub/raid/jcable/sandy/temp/

ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('../..', __FILE__), 'Gemfile')
require 'bundler/setup'
require 'fileutils'
require_relative '../lib/processing_framework'

class Amsr2Level1Clamp <  ProcessingFramework::CommandLineHelper
  default_config 'amsr2_level1'
  banner 'This tool does level1 processing for AMSR2.'

  option ['-m', '--mode'], 'mode', "The mode to process, valid options are amsr2.", default: 'amsr2'

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
                     Dir.glob(File.join(input, processing_cfg['level0_glob'])).first
                   end

      command = ". #{conf['env']} ; #{processing_cfg['driver']} -p #{processors} #{processing_cfg['options']}  #{input_file}"
      result = shell_out!(command)

      copy_output(output, '*.h5')
    end
  end
end

Amsr2Level1Clamp.run
