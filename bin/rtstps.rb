#!/usr/bin/env ruby
# RTSPS helper..

ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('../..', __FILE__), 'Gemfile')
require 'bundler/setup'
require 'fileutils'
require_relative '../lib/processing_framework'

class RtstpsClamp <  ProcessingFramework::CommandLineHelper
  @description = 'This tool does CCSDS unpacking using Rtstps for SNPP, AQUA, and TERRA.'
  @config = ProcessingFramework::ConfigLoader.default_path(__FILE__)

  option ['-c', '--config'], 'config', "The config file. Using #{@config} as the default.", default: @config
  option ['-i', '--input'], 'input', 'The input file. ', required: true

  def execute
    conf = ProcessingFramework::ConfigLoader.new(__FILE__)

    output = "#{outdir}"
    outdir += '/' + basename if basename
    basename = File.basename(input) unless basename

    platform =  basename.split('.').first

    # check platofrm
    fail "Unknown/unconfigured platform #{platform}" unless conf['configs'][platform]

    working_dir = "#{tempdir}/#{basename}"
    begin
    # make temp space
    FileUtils.rm_r(working_dir) if (File.exist?(working_dir))
    FileUtils.mkdir(working_dir)
    sourcefile = ''

    # make DATA (this is silly)
    FileUtils.mkdir(working_dir + '/data/')
    FileUtils.cd(working_dir) do
      # This part is so we don't have to tweek the DATA part of the rtsps configs.
      sourcefile = File.basename(input)
      FileUtils.cp(input, sourcefile)
      sourcefile = ProcessingFramework::CompressHelper.uncompress(sourcefile)
    end

    FileUtils.cd(working_dir + '/data/') do
      # New versions of RT-STPS require a leapsec.dat in the cwd.
      #  This assumption is made because they expect you to always run RT-STPS
      #  from its install directory.
      #  Fix this by copying the leapsec file to the cwd
      FileUtils.cp("#{ENV['RTSTPS_HOME']}/leapsec.dat", ".") if File.exists?("#{ENV['RTSTPS_HOME']}/leapsec.dat}")
      ProcessingFramework::ShellOutHelper.run_shell("#{conf['rtsps_driver']} #{conf['configs'][platform]} ../#{sourcefile}")

      # Maybe should do something else, perhaps complain?
      FileUtils.mkdir_p(output)  unless (File.exist?(output))
      # copy output
      Dir.glob('*').each do |x|
        puts "INFO: Copying #{x} to #{output}"
        FileUtils.cp(x, output)
      end
    end

    FileUtils.rm_r(working_dir)
     rescue RuntimeError => e
       puts "Error: #{e.to_s}"
       FileUtils.rm_r(working_dir) if (File.exist?(working_dir))
       exit(-1)
  end
  end
end

RtstpsClamp.run
