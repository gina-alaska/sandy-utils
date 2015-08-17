#!/usr/bin/env ruby
ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('../..', __FILE__), 'Gemfile')
require 'bundler/setup'
require 'fileutils'
require_relative '../lib/processing_framework'

class AVHRRL0Clamp <  ProcessingFramework::CommandLineHelper
  include ProcessingFramerwork::CompressHelper
  banner 'This tool processes AVHRR data to L0'

  parameter "INPUT", "The input file"
  parameter "OUTPUT", "The output directory"

  def execute

    basename = File.basename(input) unless basename
    platform = basename.split('.').first

    working_dir = "#{tempdir}/#{basename}"
    inside(working_dir) do
      sourcefile = File.basename(input)
      FileUtils.cp(input, sourcefile)
      sourcefile = uncompress(sourcefile)

      year = Time.now.strftime('%Y')
      command = "hrptin #{conf['opts']} tape_device=./#{sourcefile} pass_year=#{year} ."
      shell_out!(command)

      conf['save'].each do |pattern|
        copy_output(output, pattern)
      end
    end
  end
end

AVHRRL0Clamp.run
