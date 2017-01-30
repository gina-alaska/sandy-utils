#!/usr/bin/env ruby
ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('../..', __FILE__), 'Gemfile')
require 'bundler/setup'
require 'fileutils'
require_relative '../lib/processing_framework'

class RtstpsClamp < ProcessingFramework::CommandLineHelper
  include ProcessingFramework::CompressHelper
  banner 'This tool does CCSDS unpacking using Rtstps for SNPP, AQUA, and TERRA.'
  default_config 'rtstps'

  option ['-c', '--config'], 'config', "The config file. Using #{@config} as the default.", default: @config
  option ['-p', '--platform'], 'platform', 'The platform this data is from (npp, a1, t1)', attribute_name: :platform_type
  parameter "INPUT", "The input file"
  parameter "OUTPUT", "The output directory"

  def execute
    # Check platform
    basename = File.basename(input) unless basename

    platform = platform_type
    platform ||= basename.split(".").first

    exit_with_error("Unknown platform: #{platform}", 19) unless conf['configs'][platform]

    working_dir = "#{tempdir}/#{basename}"

    inside(working_dir) do
      # RT-STPS XML Assumes you have a data directory for it to write out to
      FileUtils.mkdir('data')
      sourcefile = File.basename(input)
      FileUtils.cp(input, sourcefile)
      sourcefile = uncompress(sourcefile)

      inside("#{working_dir}/data") do
        # RT-STPS Expects to write to ../data
        #  cd into data so that ../data exists
        # New versions of RT-STPS require a leapsec.dat in the cwd.
        #  This assumption is made because they expect you to always run RT-STPS
        #  from its install directory.
        #  Fix this by copying the leapsec file to the cwd
        leapsec_source = "#{ENV['RTSTPS_HOME']}/leapsec.dat"
        FileUtils.cp(leapsec_source, '.') if File.exist?(leapsec_source)

        shell_out!("#{conf['rtstps_driver']} #{conf['configs'][platform]} ../#{sourcefile}")

        # This is silly.  We really should have seperate scripts for snpp, aqua and terra
        if platform == "npp"
          copy_output(output, '*.h5')
        else
          copy_output(output, "*.PDS")
        end
      end
    end
  end
end

RtstpsClamp.run
