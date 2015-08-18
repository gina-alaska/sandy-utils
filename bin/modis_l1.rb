#!/usr/bin/env ruby
ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('../..', __FILE__), 'Gemfile')
require 'bundler/setup'
require 'fileutils'
require_relative '../lib/processing_framework'

class ModisL1Clamp <  ProcessingFramework::CommandLineHelper
  banner 'This tool processes Terra and Aqua data to L0'
  default_config 'modis_l1'
  parameter "INPUT", "The input directory"
  parameter "OUTPUT", "The output directory"

  def execute
    basename = File.basename(input) unless basename
    platform =  basename.split('.').first
    exit_with_error('Unknown platform..', 19) if conf['processing'][platform]

    working_dir = "#{tempdir}/#{basename}"

    inside(working_dir) do
      Dir.glob("#{input}/*.PDS").each { |pds| FileUtils.cp(pds, '.') }

      pds = Dir.glob(conf['processing'][platform]['pds'])
      exit_with_error("too many/not enough pds files => #{pds.join(' ')}", 11) if (pds.length != 1)

      # update luts
      run_with_modis_tools(conf['processing'][platform]['update_luts'], conf) if conf['processing'][platform]['update_luts']

      # To l1
      run_with_modis_tools("#{conf['processing'][platform]['l1_driver']} #{pds.first}", conf)

      # find L1A_LAC
      rLACs = Dir.glob('[AT]*L1A_LAC')
      if (rLACs.length != 1)
        fail("Found more than one L1A_LAC file - #{rLACs.join(' ')} ")
       end

      # perform gbad processing, if needed
      run_with_modis_tools(conf['processing'][platform]['gbad'], conf) if (conf['processing'][platform]['gbad'])

      # geo processing
      run_with_modis_tools("#{conf['processing'][platform]['geo_driver']} #{rLACs.first}", conf)

      # find GEOs
      rGEOs = Dir.glob('[AT]*GEO')
      if (rGEOs.length != 1)
        fail ("Found more than one GEO file - #{rGEOs.join(' ')} ")
      end

      # L1B processing
      run_with_modis_tools("#{conf['processing'][platform]['l1b_driver']} #{rLACs.first} #{rGEOs.first}", conf)

      # find  L1B_LAC
      rL1B_LACs = Dir.glob('[AT]*L1B_LAC')
      if (rL1B_LACs.length != 1)
        fail("Found more than one L1B_LAC file - #{rL1B_LACs.join(' ')} ")
      end

      # perform destriping, if needed
      run_with_modis_tools("#{conf['processing'][platform]['destripe']} #{rL1B_LACs.first}", conf) if (conf['processing'][platform]['destripe'])

      gina_name = get_gina_name(rL1B_LACs.first, platform)

      FileUtils.ln(rL1B_LACs.first, gina_name + '.cal1000.hdf')
      FileUtils.ln(rGEOs.first, gina_name + '.geo.hdf')

      # 500m
      rL1B_HKM = Dir.glob('*L1B_HKM').first
      FileUtils.ln(rL1B_HKM, gina_name + '.cal500.hdf') if (rL1B_HKM)

      # 250m
      rL1B_QKM = Dir.glob('*L1B_QKM').first
      FileUtils.ln(rL1B_QKM, gina_name + '.cal250.hdf') if (rL1B_QKM)

      conf['processing']['save'].each do |glob|
        copy_output(output, glob)
      end
    end
  end

  def get_l1_time(s)
    DateTime.strptime(s[1, 13], '%Y%j%H%M%S')
  end

  def get_gina_name(x, platform)
    platform + '.' + get_l1_time(x).strftime('%Y%m%d.%H%M')
  end

  def run_with_modis_tools(s, cfg)
    shell_out!(". #{cfg['modis_tools_setup']}; #{s}")
  end
end

ModisL1Clamp.run
