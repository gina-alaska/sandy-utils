#!/usr/bin/env ruby
## acspo processing for sst etc
# Run like:
#heap_awips_reformat.rb -t temp in out

ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('../..', __FILE__), 'Gemfile')
require 'bundler/setup'
require 'fileutils'
require_relative '../lib/processing_framework'

class Heaps4AwipsClamp <  ProcessingFramework::CommandLineHelper
  banner 'This tool converts heaps '
  default_config 'heap_awips_reformat'

  option ['-m', '--mode'], 'mode', 'mode', default: 'default'

  parameter 'INPUT', 'Input directory'
  parameter 'OUTPUT', 'Output directory'

  def execute
    exit_with_error("Unknown/unconfigured mode: #{mode}", 19) unless conf['configs'][mode]

    basename = File.basename(input) unless basename

    working_dir = "#{tempdir}/#{basename}"
    inside(working_dir) do
      processing_cfg = conf['configs'][mode]
      processing_cfg['to_process_glob'].each do |glob|
	Dir.glob(input+"/"+glob).each do |item|
		command = "#{processing_cfg['driver']} #{processing_cfg['options']} -f #{item}"
      		result = shell_out(command, clean_environment: true)
      		copy_output(output, processing_cfg['save'])
	end
      end
    end
  end
end

Heaps4AwipsClamp.run
