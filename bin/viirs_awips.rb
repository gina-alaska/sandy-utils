#!/usr/bin/env ruby
ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('../..', __FILE__), 'Gemfile')
require 'bundler/setup'
require 'fileutils'
require_relative '../lib/processing_framework'

class SnppAwipsClamp <  ProcessingFramework::CommandLineHelper
  banner 'This tool takes VIIRS data and makes it AWIPS ready.'

  option ['-p', '--processors'], 'processors', 'The number of processors to use for processing.',  environment_variable: 'PROCESSING_NUMBER_OF_CPUS', default: 1

  parameter "INPUT", "The input directory"
  parameter "OUTPUT", "The output directory"

  def execute
    mode = 'default' #TODO:  Refactor yml to not require mode.
    exit_with_error("Unknown/unconfigured mode #{mode}", 19) unless conf['configs'][mode]

    basename = File.basename(inputdir) unless basename
    processing_cfg = conf['configs'][mode]

    working_dir = "#{tempdir}/#{basename}"
    inside(working_dir)
      command = "#{conf['driver']} --num-procs #{processors} #{processing_cfg['options']} -g  #{processing_cfg['grid']}  -d #{inputdir} "
      shell_out!(command)
      Dir.glob('SSEC_AWIPS*') do |awips_file|
        gzip!(awips_file)
      end
      copy_output(output, processing_cfg['save'])
    end
  end
end

SnppAwipsClamp.run
