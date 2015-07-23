#!/usr/bin/env ruby
# terra and aqua l1 ..

ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('../..', __FILE__), 'Gemfile')
require 'bundler/setup'
require 'fileutils'
require_relative '../lib/processing_framework'

class AquaAndTerraL1Clamp <  ProcessingFramework::CommandLineHelper
  @description = 'This tool processes Terra and Aqua data to L0'
  @config = ProcessingFramework::ConfigLoader.default_path(__FILE__)

  option ['-c', '--config'], 'config', "The config file. Using #{@config} as the default.", default: @config
  option ['-i', '--input'], 'input', 'The input file. ', required: true

  def execute
    conf = ProcessingFramework::ConfigLoader.new(__FILE__)

    output = "#{outdir}"
    outdir += '/' + basename if basename
    basename = File.basename(input) unless basename

    platform =  basename.split('.').first

    working_dir = "#{tempdir}/#{basename}"
    begin
    	# make temp space
    	FileUtils.rm_r(working_dir) if (File.exist?(working_dir))
    	FileUtils.mkdir(working_dir)

	# make output space
	FileUtils.mkdir(output) if (!File.exists?(output))

    	FileUtils.cd(working_dir) do
		Dir.glob("#{input}/*.PDS").each {|pds| FileUtils.cp(pds, ".") }
                pds = Dir.glob(conf["processing"][platform]["pds"])
		raise ("too many/not enough pds files => #{pds.join(" ")}") if (pds.length != 1 )

		raise("Unknown platform..") if (!conf["processing"][platform])

		#update luts
		run_with_modis_tools(conf["processing"][platform]["update_luts"], conf) if conf["processing"][platform]["update_luts"]
		
		#To l1
		run_with_modis_tools("#{conf["processing"][platform]["l1_driver"]} #{pds.first}", conf)	

		#find L1A_LAC
		rLACs = Dir.glob("*L1A_LAC")
        	if (rLACs.length != 1 )
                	raise ("Found more than one L1A_LAC file - #{rLACs.join(" ")} ")
        	end

		#perform gbad processing, if needed
		run_with_modis_tools(conf["processing"][platform]["gbad"], conf) if ( conf["processing"][platform]["gbad"] )

		#geo processing
		run_with_modis_tools("#{conf["processing"][platform]["geo_driver"]} #{rLACs.first}", conf)

                #find GEOs 
                rGEOs = Dir.glob("*GEO")
                if (rGEOs.length != 1 )
                        raise ("Found more than one GEO file - #{rGEOs.join(" ")} ")
                end

                #L1B processing
                run_with_modis_tools("#{conf["processing"][platform]["l1b_driver"]} #{rLACs.first} #{rGEOs.first}", conf)

	        #find  L1B_LAC
                rL1B_LACs = Dir.glob("*L1B_LAC")
                if (rL1B_LACs.length != 1 )
                        raise ("Found more than one L1B_LAC file - #{rL1B_LACs.join(" ")} ")
                end

		#perform destriping, if needed
                run_with_modis_tools("#{conf["processing"][platform]["destripe"]} #{rL1B_LACs.first}", conf) if ( conf["processing"][platform]["destripe"] )

		gina_name = get_gina_name(rL1B_LACs.first, platform)
	
		FileUtils.ln(rL1B_LACs.first, gina_name+".cal1000.hdf")
		FileUtils.ln(rGEOs.first, gina_name+".geo.hdf")
		
		#500m
		rL1B_HKM = Dir.glob("*L1B_HKM").first
                FileUtils.ln(rL1B_HKM, gina_name+".cal500.hdf") if (rL1B_HKM)

		#250m
                rL1B_QKM = Dir.glob("*L1B_QKM").first
                FileUtils.ln(rL1B_QKM, gina_name+".cal250.hdf") if (rL1B_QKM)


      		conf["processing"]["save"].each do |i|
			puts("INFO: Saving #{i}")
			Dir.glob(i).each do |x|
				puts "INFO: Copying #{x} to #{output}"
        			FileUtils.cp(x, output)
			end
      		end
    		FileUtils.rm_r(working_dir)
	end
     rescue RuntimeError => e
       puts "Error: #{e.to_s}"
       #FileUtils.rm_r(working_dir) if (File.exist?(working_dir))
       exit(-1)
    end
  end

  def get_l1_time(s)
        DateTime.strptime(s[1, 13], '%Y%j%H%M%S')
  end

  def get_gina_name(x, platform)
	platform + "." + get_l1_time(x).strftime("%Y%m%d.%H%M")
  end

  def run_with_modis_tools(s, cfg)
	 ProcessingFramework::ShellOutHelper.run_shell(". #{cfg["modis_tools_setup"]}; #{s}")
  end
end

AquaAndTerraL1Clamp.run

