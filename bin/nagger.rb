#!/usr/bin/env ruby
# aggrirate data
# Run like:
# nagger.rb -t /hub/raid/jcable/sandy/temp/ in out

ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('../..', __FILE__), 'Gemfile')
require 'bundler/setup'
require 'fileutils'
require_relative '../lib/processing_framework'

class NaggerClamp <  ProcessingFramework::CommandLineHelper
  default_config 'nagger'
  banner 'Aggs data'

  parameter 'INPUT', 'Input directory'
  parameter 'OUTPUT', 'Output directory'

  def execute
    working_dir = "#{tempdir}/#{basename}"
    inside(working_dir) do
      command = File.join(File.expand_path('./', __FILE__), 'nagg.rb')
      result = shell_out(command, clean_environment: false )
      conf['save'].each do |glob|
        copy_output(output, glob)
      end
    end
  end
end

NaggerClamp.run
