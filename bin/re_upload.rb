#!/usr/bin/env ruby
ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('../..', __FILE__), 'Gemfile')
require 'bundler/setup'
require 'fileutils'
require_relative '../lib/processing_framework'
require 'date'
require 'pp'

def get_details (item)
 #npp_viirs_i04_20250205_000640_alaska_polar_fit.tif
  chunks = /(npp|noaa20|noaa21)_viirs_(i04|M12|ngfs_day_fire_rgb|ngfs_fire_temp_rgb|ngfs_microphysics_iband|true_color)_(\d{8}_\d{6})/.match(File.basename(item))
unless chunks
     #GINA format..
     chunks = /(npp|noaa20|noaa21)\.(\d{8}\.\d{4})/.match(File.basename(item))
	 return nil unless chunks
     time_of_file = DateTime.strptime(chunks[2], "%Y%m%d.%H%M")
     return { "date" => time_of_file.strftime("%Y%m%d %H%M%S"), "chunks" => chunks}
  end
  #pp chunks
  #2025_02_02_033_18_04_47
  time_of_file = DateTime.strptime(chunks[3], "%Y%m%d_%H%M%S")
  return { "date" => time_of_file.strftime("%Y%m%d %H%M%S"), "chunks" => chunks}
end


    upload_script = File.join(File.dirname(__FILE__), 're_upload')
    key = File.readlines(ENV["HOME"]+"/.re_key").join.chomp!


ARGV.each do |item|
  conf=File.open(File.join(File.dirname(__FILE__), '../config/', 're_upload.yml')) {|fd| YAML.load(fd)}
  conf["sets"].each do |type,set|
    set["glob"].gsub!("*","\\w+")
    re = Regexp.new(set["glob"])
    basename = File.basename(item)
    if re.match?(basename)
			details = get_details(File.basename(item))
			start_time = Time.now
                        command_line = [upload_script, "-k", key, item, type]
                        command_line += details["date"].split(" ")
                        puts("INFO: Running: #{command_line.join(" ")}")
			unless system(*command_line)
                          puts("ERROR: Upload failed!")
                        end
			durration = (Time.now-start_time)
			sdur = "#{durration/60.0} minutes"
			if durration < 60.0 
				sdur = "#{durration} sec"
			end
			puts("INFO: Upload took #{sdur}, a rate of #{(File.size(item)/(1024.0*1024.0))/durration} Mbytes/sec")
    end
  end
end
