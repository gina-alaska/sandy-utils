#!/usr/bin/env ruby

ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('../..', __FILE__), 'Gemfile')
require 'bundler/setup'
require 'fileutils'
require_relative '../lib/processing_framework'

class MetopL0Clamp <  ProcessingFramework::CommandLineHelper
  default_config 'metop_l1'
  banner 'This tool converts MetOp EPS to AAPP l1b.'

  option ['-s', '--spacecraft_id'], 'spacecraft id', "Spacecraft ID: [M01, M02]", required: true

  parameter "INPUT", 'The input file or directory'
  parameter "OUTPUT", 'The output directory'

  def execute

    basename = File.basename(input) unless basename
    @working_dir = "#{tempdir}/#{basename}"

    inside(@working_dir) do
      get_tle
      run_aapp_metop('AVHRR')
      if (spacecraft_id == 'M03')
        run_aapp_metop('AMSU-A MHS', '')
      else
        run_aapp_metop('HIRS AMSU-A MHS', 'HIRS')
      end
      run_aapp_metop('IASI AVHRR', 'IASI')

      # Not necessary for AWIPS at this point but I already did the work
      # Comment out and leave here in case we want to use it
      # %w(AMSU-A HIRS IASI MHS).each do |sensor|
      #   convert_bufr(sensor)
      # end
      # convert_hdf5('*.l1b')
      # convert_hdf5('*.l1c')
      copy_output(output, '*.l1*')
      copy_output(output, 'IASI*')
    end
  end

  private
  def exit_with_error(message, code)
    puts "Error: #{message}"
    exit code
  end

  def run_aapp_metop(sensors, g=' ')
    command = "AAPP_RUN_METOP -i '#{sensors}' -g '#{g}' -d #{input} -o #{@working_dir}"
    shell_out(command, env: {"TLE" => "1",
                              "PAR_NAVIGATION_DEFAULT_LISTESAT" => spacecraft_id,
                              "WRK" => "#{@working_dir}/WRK"}.merge(conf['env']))
  end

  def convert_bufr(sensor)
    sensor_filename = sensor.downcase.gsub(%r{\W}, '')
    command = "aapp_encodebufr_1c -i #{@working_dir}/#{sensor_filename}*.l1c '#{sensor}'"
    shell_out!(command)
  end

  def convert_hdf5(file)
    command = "convert_to_hdf5 -c #{@working_dir}/#{file}"
    shell_out!(command)
  end

  def get_tle
    command = 'get_tle'
    shell_out!(command)
  end

end

MetopL0Clamp.run
