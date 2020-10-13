#!/usr/bin/env ruby
# acspo processing for sst etc
# Run like:
# acspo_l2.rb -t temp -m viirs in out
require "time"

ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('../..', __FILE__), 'Gemfile')
require 'bundler/setup'
require 'fileutils'
require_relative '../lib/processing_framework'

class AMSR2_Geotiff_L2Clamp <  ProcessingFramework::CommandLineHelper
  banner 'This tool does acspo processing generating sst etc'
  default_config 'acspo_l2'

  option ['-m', '--mode'], 'mode', 'mode', default: 'default'

  parameter 'INPUT', 'Input directory'
  parameter 'OUTPUT', 'Output directory'


#AMSR2-MBT_v2r2_GW1_s202009081525290_e202009081528040_c202009081539550.nc
#AMSR2-OCEAN_v2r2_GW1_s202009081525290_e202009081528040_c202009081539550.nc
#AMSR2-PRECIP_v2r2_GW1_s202009081525290_e202009081528040_c202009081539550.nc
#AMSR2-SEAICE-NH_v2r2_GW1_s202009081525290_e202009081528040_c202009081539550.nc
#AMSR2-SEAICE-SH_v2r2_GW1_s202009081525290_e202009081528040_c202009081539550.nc
#AMSR2-SNOW_v2r2_GW1_s202009081525290_e202009081528040_c202009081539550.nc
#AMSR2-SOIL_v2r2_GW1_s202009081525290_e202009081528040_c202009081539550.nc


def runner ( s )
  puts("Runner running \"#{s}\"")
  start_time = Time.now.to_f
  system(". /opt/cspp/polar2grid_v_2_3/bin/env.sh; #{s}")
  end_time = Time.now.to_f

  run_time = (end_time-start_time)
  if ( run_time > 60)
    printf("This run took %d m\n", (end_time-start_time)/60)
  else
    printf("This run took %d s\n", (end_time-start_time))
  end
end



proj = { "gdalwarp" => "-t_srs epsg:3572 -te -3119083.496 -4596091.111 2861443.688 -946105.095 -tr 7170 7170" } 


def get_output_name(key,item, dt)
	dt.strftime("gcom-w.%Y%m%d.%H%M.#{key}.#{item}")
end

def data_process(glob, items, proj, tag)	

	co = "-co TILED=YES -co COMPRESS=DEFLATE"
	sources = Dir.glob(glob)
	if sources.length != 1
		puts("ERROR: Incorrect number of files found for #{items.join(",")}\n\t#{glob}")
		return false
	end

	source = sources.first

	dt = get_dt(source)

	#NETCDF:"AMSR2-SNOW_v2r2_GW1_s202009081525290_e202009081528040_c202009081539550.nc":Scattering_Surface_Index
	items.each do |item|
		runner("gdalwarp -rb #{proj["gdalwarp"]} #{co} NETCDF:\"#{source}:#{item}\" #{get_output_name(tag, item, dt)}.tif")
	end
end


def get_dt(item)
	#AMSR2-SNOW_v2r2_GW1_s202009081525290_e202009081528040_c202009081539550.nc
	#                     YYYYMMDDHHMMSS
	Time.strptime(File.basename(item).split("_")[3], "s%Y%m%d%H%M%S")
end



#SUBDATASET_27_NAME=NETCDF:"AMSR2-OCEAN_v2r2_GW1_s202009091603310_e202009091604250_c202009091609130.nc":Rain_Rate
#SUBDATASET_12_NAME=NETCDF:"AMSR2-OCEAN_v2r2_GW1_s202009091603310_e202009091604250_c202009091609130.nc":CLW
#SUBDATASET_22_NAME=NETCDF:"AMSR2-OCEAN_v2r2_GW1_s202009091603310_e202009091604250_c202009091609130.nc":SST
#SUBDATASET_7_NAME=NETCDF:"AMSR2-SNOW_v2r2_GW1_s202009091603310_e202009091604250_c202009091609130.nc":Snow_Depth
#SUBDATASET_8_NAME=NETCDF:"AMSR2-SNOW_v2r2_GW1_s202009091603310_e202009091604250_c202009091609130.nc":Snow_Cover
#SUBDATASET_12_NAME=NETCDF:"AMSR2-SNOW_v2r2_GW1_s202009091603310_e202009091604250_c202009091609130.nc":SWE
#NETCDF:"AMSR2-SOIL_v2r2_GW1_s202009081342420_e202009081351520_c202009081406530.nc":Soil_Moisture
# SUBDATASET_25_NAME=NETCDF:"AMSR2-OCEAN_v2r2_GW1_s202009081342420_e202009081351520_c202009081406530.nc":WSPD



  def execute
products = {  "AMSR2-SEAICE" => { "glob" => "AMSR2-SEAICE-NH*", "datasets" => ["NASA_Team_2_Ice_Concentration", "NASA_Team_2_Multiyear_Ice"]},
	"AMSR2-PRECIP" => { "glob" => "AMSR2-PRECIP*", "datasets" => ["Rain_Rate"]},
	"AMSR2-OCEAN" => { "glob" => "AMSR2-OCEAN*", "datasets" => ["CLW", "SST", "Rain_Rate", "WSPD"]},
	"AMSR2-SNOW" => { "glob" => "AMSR2-SNOW*", "datasets" => ["Snow_Depth","Snow_Cover","SWE"]},
        "AMSR2-SOIL" => { "glob" => "AMSR2-SOIL*", "datasets" => ["Soil_Moisture"]}
}

    proj = { "gdalwarp" => "-t_srs epsg:3572 -te -3119083.496 -4596091.111 2861443.688 -946105.095 -tr 3585 3585" }

    basename = File.basename(input) unless basename

    working_dir = "#{tempdir}/#{basename}"
    inside(working_dir) do

      products.each do |key,item|
           data_process("#{input}/" + item["glob"], item["datasets"], proj, key)
      end

      copy_output(output, "*.tif")
    end
  end
end

AMSR2_Geotiff_L2Clamp.run

