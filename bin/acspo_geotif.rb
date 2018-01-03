#!/usr/bin/env ruby
ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('../..', __FILE__), 'Gemfile')
require 'bundler/setup'
require 'fileutils'
require_relative '../lib/processing_framework'

class AcspoGeotifClamp  <  ProcessingFramework::CommandLineHelper
  banner 'This tool makes geotifs from Acspo data, mainly ssts'
  default_config 'acspo_geotif'

  option ['-m', '--mode'], 'mode', 'The mode to use.',  required: true
  option ['-p', '--processors'], 'processors', 'The number of processors to use for processing.',  environment_variable: 'PROCESSING_NUMBER_OF_CPUS', default: 2

  parameter 'INPUT', 'The input directory'
  parameter 'OUTPUT', 'The output directory'

  def execute
    exit_with_error("Unknown/unconfigured mode #{mode}", 19) unless conf['configs'][mode]
    processing_cfg = conf['configs'][mode]

    basename = File.basename(input) unless basename
    working_dir = "#{tempdir}/#{basename}"

    inside(working_dir) do
      grid = " --grid-configs #{get_grid_path(processing_cfg)} "


      #run the p2g commands in threads
      threads = []
      1.upto(processors.to_i) do |thread_number|
        threads << Thread.new do
	  #each p2g thread needs to run in a seperate directory so their temp files don't conflict
          FileUtils.mkdir("thread_#{thread_number}")
          loop do
            task = processing_cfg['tasks'].pop
            break if (task.nil?)
            shell_out("cd thread_#{thread_number}; #{task} #{processing_cfg['p2g_args']} #{grid} -d #{input}")
          end
          processing_cfg['save'].each do |save_glob|
            copy_output(output, "thread_#{thread_number}/" + save_glob)
          end
        end
      end

      threads.each(&:join)
    end
  end

  # gets path to the grid file.
  def get_grid_path(cfg)
    File.join(File.expand_path('../../config', __FILE__), cfg['grid_file'])
  end
end

AcspoGeotifClamp.run
