#!/usr/bin/env ruby
# Cris l2 processing tool..
# Run like:
# cris_hsrtv.rb -t /hub/raid/jcable/cris/test_data/tmp /hub/raid/jcable/cris/test_data/npp.17011.1305/ /hub/raid/jcable/cris/test_data/out/npp.17011.1306

ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('../..', __FILE__), 'Gemfile')
require 'bundler/setup'
require 'fileutils'
require_relative '../lib/processing_framework'

class CrisHsrtvClamp <  ProcessingFramework::CommandLineHelper
  default_config 'cris_hsrtv'
  banner 'This tool does HSRTV processing for CrIS.'

  parameter 'INPUT', 'Input directory'
  parameter 'OUTPUT', 'Output directory'

  def execute
    basename = File.basename(input) unless basename

    working_dir = "#{tempdir}/#{basename}"
    inside(working_dir) do
      command = " #{conf['driver']} #{conf['options']} #{input}"
      result = shell_out!(command)
    end

    Dir.glob(conf['save']).each do |hsrtv_glob|
      copy_output(output, hsrtv_glob)
    end
  end
end

CrisHsrtvClamp.run
