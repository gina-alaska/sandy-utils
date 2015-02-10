#!/usr/bin/env ruby
# Modis L1b processing

require_relative "../lib/start_up"
require "fileutils"
require_relative "../lib/processing_framework"


class ModisL1BClamp <  ProcessingFramework::CommandLineHelper

  @description = "This tool takes PDS files and makes L1b files from them."
  @config = ProcessingFramework::ConfigLoader.default_path(__FILE__)
  @conf = ProcessingFramework::ConfigLoader.new(__FILE__)

  option ["-c", "--config"], "config", "The config file. Using #{@config} as the default.", :default => @config
  option ["-i", "--inputdir"], "inputdir", "The input directory. ", :required => true

  def execute
	conf = ProcessingFramework::ConfigLoader.new(__FILE__)

	output = "#{outdir}"
	outdir += "/" + basename if basename
  	basename = File.basename(inputdir) if !basename
  


	working_dir = "#{tempdir}/#{basename}"
     	begin
		#make temp spacedministrator"
		FileUtils.rm_r(working_dir) if (File.exists?(working_dir))
		FileUtils.mkdir(working_dir)

		processing_cfg = conf["configs"]["#{mode}"]

		FileUtils.cd(working_dir) do
			#command = ". #{conf["env"]} ; #{processing_cfg["driver"]} -p #{processors} #{processing_cfg["options"]} -i #{inputdir}"
			#raise "Processing failed." if !ProcessingFramework::ShellOutHelper.run_shell(command, true)

			#raise "Processing Failed" if (ProcessingFramework::ShellOutHelper.run_shell
			raise "Processing failed." if !ProcessingFramework::ShellOutHelper.run_shell("modis_L1A.py --startnudge=0 --stopnudge=0 #{x}", true)
        		LACs = Dir.glob("*L1A_LAC")
                	raise ("Processing failed - generated than one L1A_LAC file - #{LACs.join(" ")} ")  if (LACs.length != 1 )
        		basename = File.basename(LACs.first, "L1A_LAC")

			##
			# - this part can be re-worked, should know from the start which platform the data is from
        		case ( basename[0])
                		when "T" then
                        		raise "Processing failed." if !ProcessingFramework::ShellOutHelper.run_shell("modis_GEO.py --verbose -d --threshold=95 #{basename}L1A_LAC", true)
                		when "A" then 
					new_base = "a1." + new_base
                        		raise "Processing failed." if !ProcessingFramework::ShellOutHelper.run_shell("modis_GEO.py --verbose -d --threshold=95 #{basename}L1A_LAC", true)
                		else
                        		raise ("modis_GEO.py problems - not sure what #{basename[0]} is..")
        		end
        		system("modis_L1B.py #{basename}L1A_LAC  #{basename}GEO")

        		#check and rename
        		#T2011034190833.GEO  to 20120105.1259.a1.geo.hdf
        		#01234567890123
			
			#should abstract this out.
        		t = Time.gm(2000+basename[3,2].to_i) + 24.0*60.0*60.0*(basename[5,3].to_i-1) + 60.0*60.0*basename[8,2].to_i+60.0*basename[10,2].to_i+ basename[12,2].to_i

			#gina specific file naming convention..
        		new_base = t.strftime("%Y%m%d.%H%M")

			#check that all the proper files were generated..
        		["GEO", "L1B_LAC"].each do |i|
                		raise ("Processsing Failed:  Did not generate #{basename}#{i}") if ( !File.exists?(basename + i))
        		end

	
        		#rename To Kevin's scheme - might not be needed these days..
			#adde better error msgs about all these items..
        		raise "Processing failed. Link creation falled, bad disk or filesystem?" if !ProcessingFramework::ShellOutHelper.run_shell(["ln", basename + "GEO", new_base + ".geo.hdf"])
        		raise "Processing failed. Link creation falled, bad disk or filesystem?" if !ProcessingFramework::ShellOutHelper.run_shell(["ln", basename+ "L1B_LAC", new_base + ".cal1000.hdf"])

        		#make links to the nasa style names..
        		raise "Processing failed. link creation falled, bad disk or filesystem?" if !ProcessingFramework::ShellOutHelper.run_shell(["ln", basename+ "L1B_LAC", "MOD021KM."+new_base + ".cal1000.hdf"])

        		platform_prefix = "t1."
        		platform_prefix = "a1." if ( basename[0] == "A")

        		#rename to Jay's scheme.
        		raise "Processing failed. link creation falled, bad disk or filesystem?" if !ProcessingFramework::ShellOutHelper.run_shell(["ln", basename + "GEO", platform_prefix + new_base + ".geo.hdf"])
        		raise "Processing failed: link creation falled, bad disk or filesystem?" if !ProcessingFramework::ShellOutHelper.run_shell(["ln", basename+ "L1B_LAC", platform_prefix + new_base + ".cal1000.hdf"])

        		#Make daytime links.. should revisit, and see if this is actually needed. 
        		if ( File.exists?( basename+ "L1B_HKM"))
                		link_sets = [[ basename+ "L1B_HKM",  platform_prefix +new_base + ".cal500.hdf"],
                				[ basename+ "L1B_QKM",  platform_prefix +new_base + ".cal250.hdf"],
                				[ basename+ "L1B_HKM", "MOD02HKM."+ platform_prefix +new_base + ".cal500.hdf"],
                				[ basename+ "L1B_QKM", "MOD02QKM."+ platform_prefix +new_base + ".cal250.hdf"],
                				[ basename+ "L1B_HKM", new_base + ".cal500.hdf"],
                				[ basename+ "L1B_QKM", new_base + ".cal250.hdf"]]
				link_sets.each do |set|
					 raise "Processing failed. link creation falled, bad disk or filesystem?" if !ProcessingFramework::ShellOutHelper.run_shell(["ln"] + set)
				end
        		end

			#done - copy output
			copy_output(output)
		end
		FileUtils.rm_r(working_dir)
	rescue RuntimeError => e
	      	puts ("Error: #{e.to_s}")
		FileUtils.rm_r(working_dir) if (File.exists?(working_dir))
		exit(-1)
	end
  end
end

ModisL1BClamp

.run
