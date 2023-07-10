#!/usr/bin/env ruby
# NOAA POES AAPP L1 processing
#

ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('../..', __FILE__), 'Gemfile')
require 'bundler/setup'
require 'fileutils'
require_relative '../lib/processing_framework'

class NOAAL0Clamp <  ProcessingFramework::CommandLineHelper
  default_config 'noaa_l1'
  banner 'This tool processes raw NOAA POES data to AAPP l1b.'

  parameter 'INPUT', 'The input file or directory'
  parameter 'OUTPUT', 'The output directory'

  def execute
    basename = File.basename(input) unless basename
    @working_dir = "#{tempdir}/#{basename}"

    inside(@working_dir) do
      #get_tle
      raw_input = strip_header
      run_aapp_noaa_poes(raw_input, 'AVHRR')
      copy_output(output, '*.l1*')
      run_aapp_noaa_poes(raw_input, 'AMSU-A AMSU-B MHS DCS')
      copy_output(output, '*.l1*')
    end
  end

  private

  def exit_with_error(message, code)
    puts "Error: #{message}"
    exit code
  end

  def run_aapp_noaa_poes(input_file, sensors, g = ' ')
    command = "AAPP_RUN_NOAA -i '#{sensors}' -g '#{g}' -o #{@working_dir} #{input_file}"
    shell_out(command, env: conf['env'])
  end

  def strip_header
    sourcefile = File.basename(input)
    puts "INFO: File from EOS FES.."
    FileUtils.cp(input, sourcefile)
    sourcefile = uncompress(sourcefile)
    FileUtils.mv(sourcefile, "#{sourcefile}.hrp")

    #This is needed for barrow data, if we ever get that again
    #FileUtils.cp(input, sourcefile)
    #sourcefile = uncompress(sourcefile)
    #shell_out!("dd bs=2176 if=#{sourcefile} of=#{sourcefile}.hrp skip=1")
    "#{sourcefile}.hrp"
  end

  end

  #don't fetch a tle each time run
  def get_tle
    command = 'get_tle'
    tle_pattern = Time.now.strftime('/opt/aapp/AAPP/orbelems/tle_db/%Y-%m/tle_%Y%m%d*')
    tles = Dir.glob(tle_pattern)
    # fetch tles once per day
    if (tles.length <= 1)
      shell_out!(command, env: conf['env'])
    else
      puts("INFO: skipping tle fetching, found [#{tles.join(',')}]")
    end
  end
end

NOAAL0Clamp.run
