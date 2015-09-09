#!/usr/bin/env ruby
# Tool to generate awips stuff for modis
#
# for more info see: modis_awips.rb --help

ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('../..', __FILE__), 'Gemfile')
require 'bundler/setup'
require 'fileutils'
require_relative '../lib/processing_framework'

class ModisAwipsClamp <  ProcessingFramework::CommandLineHelper
  attr_reader :processing_cfg
  banner 'This tool takes MODIS data and makes it AWIPS ready.'
  default_config 'terra_and_aqua_awips'

  option ['-m', '--mode'], 'mode', 'The mode to use.', default: 'default'
  option ['-p', '--processors'], 'processors', 'The number of processors to use for processing.',  environment_variable: 'PROCESSING_NUMBER_OF_CPUS', default: 1
  option ['-s', '--save'], 'save_pattern', 'A regular expression for the items to save - that is what items generated should be saved.', default: '*'

  parameter 'INPUT', 'The input directory'
  parameter 'OUTPUT', 'The output directory'

  def execute
    @processing_cfg = conf['configs'][mode]
    exit_with_error("Unknown mode #{mode}", 19) if processing_cfg.nil?

    basename = File.basename(input) unless basename
    working_dir = "#{tempdir}/#{basename}"

    inside(working_dir) do
      modis2awips
      crefl2awips if conf['driver_crefl']

      Dir.glob(processing_cfg['save']).each do |awips_file|
        gzip!(awips_file)
      end
      copy_output(output, processing_cfg['save'])
    end
  end

  def modis2awips
    command = [
      conf['driver'],
      "-d #{input}",
      processing_cfg['options'],
      "-g #{processing_cfg['grid']}",
      "--backend-configs #{get_config_item(processing_cfg['p2g_config'])}"
    ].join(' ')
    shell_out!(command)
  end

  # make crefl products
  # note this will fail for nighttime passes.
  def crefl2awips
    copy_and_rename(input)
    command = [
      conf['driver_crefl'],
      '-d .',
      processing_cfg['options'],
      "-g #{processing_cfg['grid']}",
      "-p #{@processing_cfg['crefl_bands']}",
      "--backend-configs #{get_config_item(processing_cfg['p2g_config'])}"
    ].join(' ')
    shell_out!(command)
  end

  # returns path to extras in config
  def get_config_item(item)
    File.join(File.expand_path('../../config', __FILE__), item)
  end

  # gets the time of the data..
  def get_time(item)
    DateTime.strptime(File.basename(item).split('.')[1, 2].join('.') + '+0', '%Y%m%d.%H%M%z')
  end

  # gets the naming scheme p2g expects..
  def get_p2g_naming(item)
    ##
    # Notes from Kathy, for polar2grid  :
    # Input naming conventions for MODIS files should be:
    # t1.YYJJJ.hhmm.1000m.hdf
    # t1.YYJJJ.hhmm.500m.hdf
    # t1.YYJJJ.hhmm.250m.hdf
    # t1.YYJJJ.hhmm.geo.hdf
    # Where YY is the last two digits of the year
    # JJJ is the Julian day of the year.
    # HH is the 2 digit hour
    # MM is the 2 digit minute
    # MODIS crefl2awips.sh will work with this naming convention.
    basename = File.basename(item)
    platform = basename.split('.')[0]
    platform + '.' + get_time(item).strftime('%y%j.%H%M')
  end

  def copy_and_rename(inputdir)
    mapper = { 'cal1000.hdf' => '1000m.hdf', 'cal500.hdf' => '500m.hdf', 'cal250.hdf' => '250m.hdf', 'geo.hdf' => 'geo.hdf' }
    pg_basename = get_p2g_naming(Dir.glob(inputdir + '/*.geo.hdf').first)
    # note - copy not link, link causes it to use the file name of the target, not the renamed file.
    mapper.keys.each do |z|
      hdf = Dir.glob(inputdir + '/*' + z).first
      FileUtils.cp(hdf, pg_basename + '.' + mapper[z]) if (hdf)
    end
  end
end

ModisAwipsClamp.run
