#!/usr/bin/env ruby
# mirs for atmp
# Run like:
# mirs_atms.rb -t /hub/raid/jcable/sandy/temp/ in out

ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('../..', __FILE__), 'Gemfile')
require 'bundler/setup'
require 'fileutils'
require_relative '../lib/processing_framework'

class MirsL0Clamp <  ProcessingFramework::CommandLineHelper
  default_config 'mirs_l0'
  banner 'This tool does MIRS processing for ATMS.'
  option ['-s', '--sensor'], 'sensor', 'The sensor this data is from (atms)', attribute_name: :sensor

  parameter 'INPUT', 'Input directory'
  parameter 'OUTPUT', 'Output directory'

  def execute
    exit_with_error('Unknown sensor..', 19) if conf['processing'][sensor].nil?

    basename = File.basename(input) unless basename

    working_dir = "#{tempdir}/#{basename}"
    inside(working_dir) do
      command = "#{conf['processing'][sensor]['driver']} -i #{input}"
      result = shell_out!(command, clean_environment: true )
      conf['processing'][sensor]['save'].each do |glob|
        copy_output(output, glob)
      end
    end
  end
end

MirsL0Clamp.run
