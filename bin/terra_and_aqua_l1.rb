#!/usr/bin/env ruby
ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('../..', __FILE__), 'Gemfile')
require 'bundler/setup'
require 'fileutils'
require 'date'
require_relative '../lib/processing_framework'

class ModisL1Clamp <  ProcessingFramework::CommandLineHelper
  banner 'This tool processes Terra and Aqua data to L0'
  default_config 'terra_and_aqua_l1'

  option ['-p', '--platform'], 'platform', 'The platform this data is from (a1, t1)', attribute_name: :platform_type

  parameter 'INPUT', 'The input directory'
  parameter 'OUTPUT', 'The output directory'

  def execute
    basename = File.basename(input) unless basename
    platform = platform_type
    platform ||= basename.split(".").first

    exit_with_error('Unknown platform..', 19) if conf['processing'][platform].nil?

    working_dir = "#{tempdir}/#{basename}"

    inside(working_dir) do
      Dir.glob("#{input}/*.PDS").each { |pds| FileUtils.cp(pds, '.') }

      pds = Dir.glob(conf['processing'][platform]['pds'])
      exit_with_error("too many/not enough pds files => #{pds.join(' ')}", 11) if (pds.length != 1)

      # update luts
      shell_out_clean(conf['processing'][platform]['update_luts'], conf) if conf['processing'][platform]['update_luts']

      # To l1
      shell_out_clean("#{conf['processing'][platform]['l1_driver']} #{pds.first}",conf)

      # find L1A_LAC
      rLACs = Dir.glob('[AT]*L1A_LAC')
      if (rLACs.length != 1)
        fail("Found more than one L1A_LAC file - #{rLACs.join(' ')} ")
      end

      # perform gbad processing, if needed
      shell_out_clean(conf['processing'][platform]['gbad'], conf) if (conf['processing'][platform]['gbad'])

      # geo processing
      shell_out_clean("#{conf['processing'][platform]['geo_driver']} #{rLACs.first}", conf)

      # find GEOs
      rGEOs = Dir.glob('[AT]*GEO')
      if (rGEOs.length != 1)
        fail ("Found more than one GEO file - #{rGEOs.join(' ')} ")
      end

      # L1B processing
      shell_out_clean("#{conf['processing'][platform]['l1b_driver']} #{rLACs.first} #{rGEOs.first}", conf)

      # find  L1B_LAC
      rL1B_LACs = Dir.glob('[AT]*L1B_LAC')
      if (rL1B_LACs.length != 1)
        fail("Found more than one L1B_LAC file - #{rL1B_LACs.join(' ')} ")
      end

      # perform destriping, if needed
      shell_out_clean("#{conf['processing'][platform]['destripe']} #{rL1B_LACs.first}", conf) if (conf['processing'][platform]['destripe'])

      gina_name = get_gina_name(rL1B_LACs.first, platform, get_l1_time(rGEOs.first))

      FileUtils.mv(rL1B_LACs.first, gina_name + '.1000m.hdf')
      FileUtils.mv(rGEOs.first, gina_name + '.geo.hdf')

      # 500m - not produced for night passes
      rL1B_HKM = Dir.glob('*L1B_HKM').first
      FileUtils.mv(rL1B_HKM, gina_name + '.500m.hdf') if (rL1B_HKM)

      # 250m - not produced for night passes
      rL1B_QKM = Dir.glob('*L1B_QKM').first
      FileUtils.mv(rL1B_QKM, gina_name + '.250m.hdf') if (rL1B_QKM)

      conf['processing']['save'].each do |glob|
        copy_output(output, glob)
      end
    end
  end

  def get_l1_time(s)
    DateTime.strptime(s[1, 13], '%Y%j%H%M%S')
  end

  # gets the naming scheme p2g expects..
  def get_gina_name(item, platform, pass_tm)
    ##
    # Notes from Kathy, on naming conventions:
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
    platform + '.' + pass_tm.strftime('%y%j.%H%M')
  end

  #sources  "modis_tools_setup" before running the command to setup the environment.
  def shell_out_clean(cmd, cfg)
    if cfg["clean_env"]
      shell_out!(cmd, clean_environment: true )
    else
      shell_out!(cmd)
    end
  end
end

ModisL1Clamp.run
