#!/usr/bin/env ruby
# Tool to generate awips stuff for modis
#
# for more info see: modis_awips.rb --help

ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('../..', __FILE__), 'Gemfile')
require 'bundler/setup'
require 'fileutils'
require_relative '../lib/processing_framework'

class TerraAndAquaAwipsClamp <  ProcessingFramework::CommandLineHelper
  @description = 'This tool takes VIIRS data and makes it AWIPS ready .'
  @config = ProcessingFramework::ConfigLoader.default_path(__FILE__)
  @conf = ProcessingFramework::ConfigLoader.new(__FILE__)

  option ['-c', '--config'], 'config', "The config file. Using #{@config} as the default.", default: @config
  option ['-i', '--inputdir'], 'inputdir', 'The input directory. ', required: true
  option ['-m', '--mode'], 'mode', "The mode to use #{@conf['configs'].keys.join(',')}.", default: 'default'
  option ['-p', '--processors'], 'processors', 'The number of processors to use for processing.',  environment_variable: 'PROCESSING_NUMBER_OF_CPUS', default: @conf['limits']['processor']
  option ['-s', '--save'], 'save_pattern', 'A regular expression for the items to save - that is what items generated should be saved.', default: @conf['configs']['default']['save']

  def execute
    conf = ProcessingFramework::ConfigLoader.new(__FILE__)

    output = "#{outdir}"
    outdir += '/' + basename if basename
    basename = File.basename(inputdir) unless basename

    processing_cfg = conf['configs']["#{mode}"]

    # check mode
    fail "Unknown/unconfigured mode #{mode}" unless conf['configs'][mode]

    working_dir = "#{tempdir}/#{basename}"

    begin
     # make temp space
     FileUtils.rm_r(working_dir) if (File.exist?(working_dir))
     FileUtils.mkdir(working_dir)

     FileUtils.cd(working_dir) do
       command = "#{processing_cfg['options']} -g  #{processing_cfg['grid']} --backend-configs #{get_config_item(processing_cfg['p2g_config'])}"
       unless (ProcessingFramework::ShellOutHelper.run_shell("#{conf['driver']} -d #{inputdir} #{command}"))
         # polar to grid seems to say fail a lot, even when it works - just print warning
         puts "INFO: #{conf['driver']} says it failed, but ignoring."
       end

       if conf['driver_crefl']
         copy_and_rename(inputdir)
         unless (ProcessingFramework::ShellOutHelper.run_shell("#{conf['driver_crefl']} -d . #{command}"))
           # polar to grid seems to say fail a lot, even when it works - just print warning
           puts "INFO: #{conf['driver_crefl']} says it failed, but ignoring."
         end
       end

       Dir.glob(processing_cfg['save']) do |awips_file|
         ProcessingFramework::ShellOutHelper.run_shell("gzip -v #{awips_file}")
         File.rename("#{awips_file}.gz", awips_file)
       end
       copy_output(output, processing_cfg['save'])
     end
     # FileUtils.rm_r(working_dir)
   rescue RuntimeError => e
     puts "Error: #{e.to_s}"
     # FileUtils.rm_r(working_dir) if (File.exist?(working_dir))
     exit(-1)
   end
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
    mapper.keys.each { |z| FileUtils.cp(Dir.glob(inputdir + '/*' + z).first, pg_basename + '.' + mapper[z]) }
  end
end

TerraAndAquaAwipsClamp.run
