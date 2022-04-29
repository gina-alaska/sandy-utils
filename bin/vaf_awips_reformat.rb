#!/usr/bin/env ruby
# Run like:
# vaf_awips_reformat.rb -t temp in out

ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('..', __dir__), 'Gemfile')
require 'bundler/setup'
require 'fileutils'
require_relative '../lib/processing_framework'

class Vaf4AwipsClamp < ProcessingFramework::CommandLineHelper
  banner 'This tool converts heaps '
  default_config 'vaf_awips_reformat'

  option ['-m', '--mode'], 'mode', 'mode', default: 'default'

  parameter 'INPUT', 'Input directory'
  parameter 'OUTPUT', 'Output directory'

  def execute
    exit_with_error("Unknown/unconfigured mode: #{mode}", 19) unless conf['configs'][mode]

    basename ||= File.basename(input)

    working_dir = "#{tempdir}/#{basename}"
    inside(working_dir) do
      processing_cfg = conf['configs'][mode]
      processing_cfg['to_process_glob'].each do |glob|
        Dir.glob(input + '/' + glob).each do |item|
          FileUtils.cp(item, '.')
          command = "#{processing_cfg['driver']} #{processing_cfg['options']} -f #{File.basename(item)}"
          result = shell_out(command, clean_environment: true)
        end
      end
      processing_cfg['save'].each do |pattern|
        copy_output(output, pattern)
      end
    end
  end
end
