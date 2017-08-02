#!/usr/bin/env ruby
ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('../..', __FILE__), 'Gemfile')
require 'bundler/setup'
require 'fileutils'
require_relative '../lib/processing_framework'

class SportSliceClamp <  ProcessingFramework::CommandLineHelper
  banner 'This tool makes geotifs from modis and viirs data .'
  default_config 'p2g_geotif'

  option ['-m', '--mode'], 'mode', 'The mode to use.',  required: true
  option ['-p', '--processors'], 'processors', 'The number of processors to use for processing.',  environment_variable: 'PROCESSING_NUMBER_OF_CPUS', default: 1

  parameter 'INPUT', 'The input directory'
  parameter 'OUTPUT', 'The output directory'

  def execute
    exit_with_error("Unknown/unconfigured mode #{mode}", 19) unless conf['configs'][mode]
    processing_cfg = conf['configs'][mode]

    basename = File.basename(input) unless basename
    working_dir = "#{tempdir}/#{basename}"

    inside(working_dir) do
      # if grid is defined in config, use it
      grid = ''
      if processing_cfg['grid']
        grid = " --grid-configs #{get_grid_path(processing_cfg)} "
      end

      # do each task
      processing_cfg['tasks'].each do |task|
        shell_out("#{task} #{grid} -d #{input}")
      end

      # compress output
      Dir.glob(processing_cfg['save']).each do |awips_file|
        gzip!(awips_file)
      end

      # copy output
      copy_output(output, processing_cfg['save'])
    end
  end

  # gets path to the grid file.
  def get_grid_path(cfg)
    File.join(File.expand_path('../../config', __FILE__), cfg['grid_file'])
  end
end

SportSliceCamp.run
