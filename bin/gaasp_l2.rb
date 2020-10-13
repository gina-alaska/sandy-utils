#!/hab/pkgs/core/ruby/2.5.1/20180424193230/bin/ruby
# acspo processing for sst etc
# Run like:
# gaasp_l2.rb -t temp in out

ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('../..', __FILE__), 'Gemfile')
require 'bundler/setup'
require 'fileutils'
require_relative '../lib/processing_framework'

class GaaspL2Clamp <  ProcessingFramework::CommandLineHelper
  banner 'This tool does acspo processing generating sst etc'
  default_config 'gaasp_l2'

  option ['-m', '--mode'], 'mode', 'mode', default: 'default'

  parameter 'INPUT', 'Input directory'
  parameter 'OUTPUT', 'Output directory'

  def execute
    exit_with_error("Unknown/unconfigured mode: #{mode}", 19) unless conf['configs'][mode]

    basename = File.basename(input) unless basename

    working_dir = "#{tempdir}/#{basename}"
    inside(working_dir) do
      processing_cfg = conf['configs'][mode]

      command = "#{processing_cfg['driver']} #{processing_cfg['options']} -i #{input}"
      result = shell_out(command, clean_environment: true)

      copy_output(output, processing_cfg['save'])
    end
  end
end

GaaspL2Clamp.run
