#!/usr/bin/env ruby
# AWS Level1 Tool..
# Run like:
# /aws_leveli1.rb in out

ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('../..', __FILE__), 'Gemfile')
require 'bundler/setup'
require 'fileutils'
require_relative '../lib/processing_framework'




class AwsLevel1Clamp <  ProcessingFramework::CommandLineHelper
  default_config 'aws'
  banner 'This tool does Level1 processing for AWS.'

  parameter "INPUT", "Input directory"
  parameter "OUTPUT", "Output directory"

  def execute

    basename = File.basename(input) unless basename

    working_dir = "#{tempdir}/#{basename}"
    inside(working_dir) do
      input_file = Dir.glob(input + '/t*.dat').first
      puts("INFO: using #{input_file} as level0 file.")
      FileUtils.cp(input_file, ".")


      command = ". #{conf['env']} ; #{conf['driver']} #{conf['options']} #{File.basename(input_file)}"
      result = shell_out!(command)

      copy_output(output, '*.nc')
    end
  end
end

AwsLevel1Clamp.run
