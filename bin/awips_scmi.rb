#!/usr/bin/env ruby
ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('../..', __FILE__), 'Gemfile')
require 'bundler/setup'
require 'fileutils'
require_relative '../lib/processing_framework'

class AwipsScmiClamp <  ProcessingFramework::CommandLineHelper
  banner 'This tool takes l1 data and generates SCMI tiles for awips.'
  default_config 'awips_scmi'

  option ['-p', '--processors'], 'processors', 'The number of processors to use for processing.',  environment_variable: 'PROCESSING_NUMBER_OF_CPUS', default: 1
  option ['-m', '--mode'], 'mode', "The sensor to process to SCMI", default: 'viirs'

  parameter "INPUT", "The input directory"
  parameter "OUTPUT", "The output directory"

  def execute
    exit_with_error("Unknown/unconfigured mode #{mode}", 19) unless conf['configs'][mode]

    basename = File.basename(input) unless basename
    @processing_cfg = conf['configs'][mode]

    working_dir = "#{tempdir}/#{basename}"
    inside(working_dir) do
      @processing_cfg["tasks"].each_pair do |type,options|
        scmi_gen(type,options,conf, input)
      end
      copy_output(output, @processing_cfg['save'])
    end
  end
 
  def scmi_gen(type, options,config, inputdir) 
	   options.each_pair do |_name, task|
   		 config_options = " --backend-configs #{get_config_item(@processing_cfg["p2g_config"])} " +
    			" --grid-configs #{get_config_item(@processing_cfg["p2g_grid"])} "
   
   		 command = " #{config["driver"]} #{type} scmi -g #{task["grid"]} -d #{inputdir} "  +
    			" #{@processing_cfg["options"]} " + 
    			config_options + 
    			" -p #{task["bands"]} "
		 puts command
		 shell_out(command)
   	end
  end

  def get_config_item(item)
    File.join(File.expand_path('../../config', __FILE__), item)
  end
end

AwipsScmiClamp.run
