#!/usr/bin/env ruby
# firepoint processing
# Run like:
# modis_mod14.rb -t temp in out

ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('../..', __FILE__), 'Gemfile')
require 'bundler/setup'
require 'fileutils'
require_relative '../lib/processing_framework'

class ModisMod14Clamp <  ProcessingFramework::CommandLineHelper
  banner 'This tool does firepoint processing for modis'
  default_config 'modis_mod14'

  option ['-m', '--mode'], 'mode', 'mode', default: 'default'

  parameter 'INPUT', 'Input directory'
  parameter 'OUTPUT', 'Output directory'

  def execute
    exit_with_error("Unknown/unconfigured mode: #{mode}", 19) unless conf['configs'][mode]

    basename = File.basename(input) unless basename

    working_dir = "#{tempdir}/#{basename}"
    inside(working_dir) do
      processing_cfg = conf['configs'][mode]

      hdf_geo = Dir.glob(input + '/*.geo.hdf').first
      hdf_1k = Dir.glob(input + '/*1000m.hdf').first
      fire_points = get_output_filename(hdf_geo, processing_cfg)

      command = "#{processing_cfg['driver']} #{processing_cfg['options']}  #{hdf_1k} #{hdf_geo} #{fire_points}"
      result = shell_out!(command)

      command = "#{processing_cfg['txt_driver']} #{fire_points} > #{fire_points}.txt"
      result = shell_out!(command)

      copy_output(output, processing_cfg['save'])
    end
  end

  def get_output_filename(geo, cfg)
    get_platform(geo) + '.' + get_modis_l1_time(geo).strftime(cfg['output'])
  end

  def get_platform(s)
    puts(s)
    File.basename(s)[0, 2]
  end

  def get_modis_l1_time(s)
    filename = File.basename(s)
    puts filename[3, 10]
    DateTime.strptime(filename[3, 10], '%y%j.%H%M')
  end

  def copy_output(output, list)
    # add trailing slash, if needed
    output += '/' if output[-1] != '/'

    FileUtils.mkdir_p(output)  unless (File.exist?(output))
    list.each do |glob|
      Dir.glob(glob).each { |x| FileUtils.cp(x, output) }
    end
  end
end

ModisMod14Clamp.run
