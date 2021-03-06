#!/usr/bin/env ruby
ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('../..', __FILE__), 'Gemfile')
require 'bundler/setup'
require 'fileutils'
require_relative '../lib/processing_framework'

class P2gGeotifClamp <  ProcessingFramework::CommandLineHelper
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
      grid = " --grid-configs #{get_grid_path(processing_cfg)} "
      rescale = get_rescale_path(processing_cfg)


      #run the p2g commands in threads
      threads = []
      1.upto(processors.to_i) do |thread_number|
        threads << Thread.new do
	  #each p2g thread needs to run in a seperate directory so their temp files don't conflict
          FileUtils.mkdir("thread_#{thread_number}")
          loop do
            task = processing_cfg['tasks'].pop
            break if (task.nil?)

            in_file_args = "-d #{input} "
            in_file_args = "-f #{input}/*IMG* " if mode.include?("mirs")
            in_file_args = "-f #{input}/*L1DLBTBR*.h5 " if mode.include?("amsr2")

            shell_out("cd thread_#{thread_number}; #{task} #{processing_cfg['p2g_args']} #{grid} #{rescale} #{in_file_args}")
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

  def get_rescale_path(cfg)

    if ( ! cfg['rescale'] )
	return " " 
    else 
    	return [ "--rescale-config", File.join(File.expand_path('../../config', __FILE__), cfg['rescale'])].join(" ")
    end 
  end

end

P2gGeotifClamp.run
