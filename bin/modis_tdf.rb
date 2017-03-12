#!/usr/bin/env ruby
#
# hdf to tdf conversion, mainly for AVO/USGS
#

ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('../..', __FILE__), 'Gemfile')
require 'bundler/setup'
require 'fileutils'
require_relative '../lib/processing_framework'

class ModisTdfClamp <  ProcessingFramework::CommandLineHelper
  banner 'This tool makes tdf files from hdf'
  default_config 'modis_tdf'

  #
  option ['-p', '--platform'], 'platform', 'The platform, aqua-1 or terra-1 with terra-1 the default.', default: 'terra-1'
  parameter 'INPUT', 'The input directory'
  parameter 'OUTPUT', 'The output directory'

  def execute
    basename = File.basename(input) unless basename
    @processing_cfg = conf
    working_dir = "#{tempdir}/#{basename}"
    inside(working_dir) do
      # This copy should be unneeded, but seaspace scripts don't like paths and they could modify source data, so cping.
      Dir.glob(input + '/*.hdf') { |hdf| FileUtils.cp(hdf, '.') }

      hdf_geo = get_hdf('geo')
      hdf_1k = get_hdf('1000m')
      hdf_qk = get_hdf('250m')
      hdf_hk = get_hdf('500m')

      # these should always exist
      exit_with_error('Missing 1k hdf file', -1) unless hdf_1k
      exit_with_error('Missing geo hdf file', -1) unless hdf_geo

      if hdf_qk
        # day time
        tdf_day_convertsion(hdf_1k, hdf_hk, hdf_qk, hdf_geo, platform)
      else
        # night - just 1k stuff
        tdf_night_convertsion(hdf_1k, hdf_geo, platform)
      end

      # run the additional conversion steps on the tdf files made above
      tdfs = Dir.glob('*_tdf')
      exit_with_error('The terascan tdf to hdf conversion failed', -1) unless tdfs.length > 0
      tdfs.each { |tdf| tdf_additions(tdf, basename) }

      copy_output(output, @processing_cfg['save'])
    end
  end

  # this does a few additional conversion steps, including renaming the variables.  I am not sure why some of these are done, besides historical reasons.
  def tdf_additions(tdf, basename)
    # bow tie
    command = [
      '/opt/terascan/bin/modis_bt',
      'channels=' + @processing_cfg['terascan']['modis_bt_channels'],
      tdf,
      tdf + '.bt'].join(' ')
    terascan_run(command)

    # compute brightness temps
    command = ['/opt/terascan/bin/modis_bright', tdf + '.bt', tdf + '.bt.tdf'].join(' ')
    terascan_run(command)

    # get variable names
    command = ["/opt/terascan/bin/varnames include_vars='modis_ch[23][0-9]b'",  tdf + '.bt.tdf'].join(' ')
    names = terascan_run(command)

    # loop though names,
    names.stdout.split.each do |name|
      puts "Info: Renaming #{name}"
      command = ['/opt/terascan/bin/varname', 'old_var_name=' + name,  'new_var_name=' + name + '_temp', tdf + '.bt.tdf'].join(' ')
      terascan_run(command)
    end

    FileUtils.mv(tdf + '.bt.tdf', basename + '.modis_bright.tdf')
    FileUtils.mv(tdf + '.bt', basename + '.modis_cal.tdf')
  end

  # does night conversion - no 250k or 500k
  def tdf_night_convertsion(hdf_1k, hdf_geo, platform)
    command = [
      get_config_item(@processing_cfg['terascan']['night_tdf']),
      'NA',
      'NA',
      hdf_1k,
      'radiance',
      platform,
      hdf_geo].join(' ')
    terascan_run(command)
  end

  # does day conversion
  def tdf_day_convertsion(hdf_1k, hdf_hk, hdf_qk, hdf_geo, platform)
    command = [
      get_config_item(@processing_cfg['terascan']['day_tdf']),
      hdf_qk,
      hdf_hk,
      hdf_1k,
      'radiance',
      platform,
      hdf_geo].join(' ')
    terascan_run(command)
  end

  # returns path to the requested hdf file in the input directory
  def get_hdf(postfix)
    Dir.glob('*' + postfix + '.hdf').first
  end

  # returns path to extras in config
  def get_config_item(item)
    File.join(File.expand_path('../../config', __FILE__), item)
  end

  # runs after sourcing the tscan config. Used for terascan comamnds.
  def terascan_run(command)
    results = shell_out!(". #{@processing_cfg['terascan']['driver']} ;  #{command}", 'env' => { 'SHELL' => '/bin/bash' })
    exit_with_error("The terascan command #{command} failed", -1) unless results.status.success?
    results
  end
end

ModisTdfClamp.run
