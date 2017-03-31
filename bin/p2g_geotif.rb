#!/usr/bin/env ruby
ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('../..', __FILE__), 'Gemfile')
require 'bundler/setup'
require 'fileutils'
require_relative '../lib/processing_framework'

class P2gGeotifClamp <  ProcessingFramework::CommandLineHelper
  banner 'This tool makes geotifs from modis and viirs data .'
  default_config 'p2g_geotif'

  option ['-m', '--mode'], 'mode', 'The mode to use.',  required: true

  parameter 'INPUT', 'The input directory'
  parameter 'OUTPUT', 'The output directory'

  def execute
    exit_with_error("Unknown/unconfigured mode #{mode}", 19) unless conf['configs'][mode]
    processing_cfg = conf['configs'][mode]

    basename = File.basename(input) unless basename
    working_dir = "#{tempdir}/#{basename}"

    inside(working_dir) do
      grid = " --grid-configs #{get_grid_path(processing_cfg)} "
      processing_cfg['tasks'].each do |task|
        # generates errors, if some products are not generated, like for example at night
        shell_out("#{task} #{processing_cfg['p2g_args']} #{grid} -d #{input}")
      end
      processing_cfg['save'].each do |save_glob|
        copy_output(output, save_glob)
      end
    end
  end

  # gets path to the grid file.
  def get_grid_path(cfg)
    File.join(File.expand_path('../../config', __FILE__), cfg['grid_file'])
  end
end

P2gGeotifClamp.run
