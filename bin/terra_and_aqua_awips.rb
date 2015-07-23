#!/usr/bin/env ruby
# Tool to generate awips stuff for viirs
#
# for more info see: viirs_awips.rb --help

ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('../..', __FILE__), 'Gemfile')
require 'bundler/setup'
require 'fileutils'
require_relative '../lib/processing_framework'

class SnppAwipsClamp <  ProcessingFramework::CommandLineHelper
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

       command = "#{processing_cfg['options']} -g  #{processing_cfg['grid']}  -d #{inputdir} --backend-configs #{get_config_item(processing_cfg["p2g_config"])}"
       unless (ProcessingFramework::ShellOutHelper.run_shell("#{conf['driver']} #{command}"))
         # polar to grid seems to say fail a lot, even when it works - just print warning
         puts "INFO: #{conf['driver']} says it failed, but ignoring."
       end

      if conf['driver_crefl']
       unless (ProcessingFramework::ShellOutHelper.run_shell("#{conf['driver_crefl']} #{command}"))
         # polar to grid seems to say fail a lot, even when it works - just print warning
         puts "INFO: #{conf['driver_crefl']} says it failed, but ignoring."
       end
      end

       Dir.glob(processing_cfg["save"]) do |awips_file|
         ProcessingFramework::ShellOutHelper.run_shell("gzip -v #{awips_file}")
         File.rename("#{awips_file}.gz", awips_file)
       end
       copy_output(output, processing_cfg['save'])
     end
     #FileUtils.rm_r(working_dir)
   rescue RuntimeError => e
     puts "Error: #{e.to_s}"
     #FileUtils.rm_r(working_dir) if (File.exist?(working_dir))
     exit(-1)
   end
  end

  #returns path to extras in config
  def get_config_item(item)
         File.join(File.expand_path('../../config', __FILE__), item)
  end

end

SnppAwipsClamp.run
