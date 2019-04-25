#!/usr/bin/env ruby
# firepoint processing
# Run like:
# noaa_viirs_fire.rb  -t temp in out

ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('..', __dir__), 'Gemfile')
require 'bundler/setup'
require 'fileutils'
require_relative '../lib/processing_framework'

class NoaaViirsFireClamp < ProcessingFramework::CommandLineHelper
  banner 'This tool does NOAA VIIRS fire detections'
  default_config 'noaa_viirs_fire'

  option ['-m', '--mode'], 'mode', 'mode', default: 'default'

  parameter 'INPUT', 'Input directory'
  parameter 'OUTPUT', 'Output directory'

  def execute
    exit_with_error("Unknown/unconfigured mode: #{mode}", 19) unless conf['configs'][mode]

    basename ||= File.basename(input)

    working_dir = "#{tempdir}/#{basename}"
    inside(working_dir) do
      processing_cfg = conf['configs'][mode]

      processing_cfg.each do |key,set|
        command = "#{set['command']} #{input}"
        result = shell_out!(command)
        copy_output(output, set['save'])
      end
    end
  end
end

NoaaViirsFireClamp.run
