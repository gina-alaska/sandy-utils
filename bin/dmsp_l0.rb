#!/usr/bin/env ruby
ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('../..', __FILE__), 'Gemfile')
require 'bundler/setup'
require 'fileutils'
require_relative '../lib/processing_framework'

class DMSPL0Clamp <  ProcessingFramework::CommandLineHelper
  banner 'This tool processes DMSP data to L0'
  default_config 'dmsp_l0'
  
  parameter "INPUT", "The input file"
  parameter "OUTPUT", "The output file"

  def execute
    basename = File.basename(input) unless basename
    working_dir = "#{tempdir}/#{basename}"

    inside(working_dir)
      sourcefile = File.basename(input)
      FileUtils.cp(input, sourcefile)
      sourcefile = uncompress(sourcefile)
      tm = DateTime.strptime(sourcefile.split('.')[1, 2].join('.'), '%y%j.%H%M%S')

      command = "rtdin #{conf['opts']} tape_device=./#{sourcefile} pass_date=#{tm.strftime('%Y.%j')} pass_time=#{tm.strftime('%H:%M:%S')} satellite=f-#{sourcefile.split('.').first[1, 2]}  ."
      shell_out!(". #{conf['terascan_driver']} ;  #{command}")

      conf['save'].each do |glob|
        copy_output(output, glob)
      end
    end
  end
end

DMSPL0Clamp.run
