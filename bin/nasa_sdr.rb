#!/usr/bin/env ruby
# SDR processing tool..
# Run like:
# /snpp_sdr.rb --inputdir /hub/raid/jcable/sandy/source/npp_test/ -m viirs -p 2 -o /hub/raid/jcable/sandy/output/test_viirs/ -t /hub/raid/jcable/sandy/temp/

ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('../..', __FILE__), 'Gemfile')
require 'bundler/setup'
require 'fileutils'
require_relative '../lib/processing_framework'

require 'pp'

class SnppViirsSdrClamp <  ProcessingFramework::CommandLineHelper
  default_config 'nasa_sdr'
  banner 'This tool does SDR processing for SNPP using the NASA toolset.'

  option ['-m', '--mode'], 'mode', "The SDR to process, valid options are viirs.", default: 'viirs'
  option ['-p', '--processors'], 'processors', 'The number of processors to use for processing.',  environment_variable: 'PROCESSING_NUMBER_OF_CPUS', default: 1

  parameter "INPUT", "Input directory"
  parameter "OUTPUT", "Output directory"

  def execute
    exit_with_error("Unknown/unconfigured mode: #{mode}", 19) unless conf['configs'][mode]

    basename = File.basename(input) unless basename

    working_dir = "#{tempdir}/#{basename}"
    inside(working_dir) do
      processing_cfg = conf['configs'][mode]

      input_file = if File.exist?(input) && !File.directory?(input)
                     input
                   else
                     Dir.glob(File.join(input, processing_cfg['rdr_glob'])).first
                   end

      puts build_sdr_command_line(processing_cfg, input)

      #command = ". #{conf['env']} ; #{processing_cfg['driver']} -p #{processors} #{processing_cfg['options']}  #{input_file}"
      #result = shell_out!(command)

      #copy_output(output, '*.h5')
    end
  end



 def build_sdr_command_line(cfg, input) 

	tm_of_data = get_time_of_data(input)
	tm_of_end_data = get_time_of_end_of_data(input)

	command = "" 
	
	#command to run
	command += cfg["driver"] + " " 
	
	#get anc files
	command += " " + get_anc_options(cfg, tm_of_data) + " " 
	
	#get output commands
	command += " " + get_output_line(cfg, tm_of_data, tm_of_end_data) + " "

	#add input
	command += " " + cfg["input"].keys.first + " " + get_a_rdr(input, cfg) + " "

	command
 end


 def get_output_line(cfg, tm_of_data,tm_of_end_of_data) 
	command_line = []
	time_now = Time.now.utc
	cfg["output"].each do |item|
		command_line << item + " " +  get_output_item(item, tm_of_data,tm_of_end_of_data, time_now)
	end	

	command_line.join(" ")
 end




 #formats the output file name
 # Note -> tm_of_end_of_data isn't a tm object, but a string from the file name with the utc data of the end of the pass
 def get_output_item(item, tm_of_start_of_data,tm_of_end_of_data, tm_now)
	name = []
	
	#strip out the leading bit, viirs.gdnbo => gdnbo
	name << item.split(".")[1].upcase
	
	#hard coded to npp, fix me
	name << "npp" 

	#date
	name << tm_of_start_of_data.strftime("d%Y%m%d")
	
	#start time
	name << tm_of_start_of_data.strftime("t%H%M%S0")

	#end time 
	name << tm_of_end_of_data	
		
	#orbit - just set to 1, it isn't possible to figure out the correct number
        name << "b00001"

	#time of creation
	name << tm_now.strftime("c%Y%m%d%H%M%S%6N")

	#source
	name << "gina"

	name.join("_") + ".h5"
 end


 # finds anc stuff, locates the correct files, and builds commandline
 def get_anc_options(cfg, tm_of_data)
	get_anc(cfg, tm_of_data)
	command = ""
	cfg["anc"].each do |key,values|
		command += " #{values["name"]} #{values["path"]} "	
        end

	command
 end

# finds anc files for each item
 def get_anc(cfg, tm_of_data)
	cfg["anc"].each do |name, set|
		set["path"] = get_anc_set(set, tm_of_data)
	end
 end

#gets the anc for a particular item.
  def get_anc_set(set, tm_of_data)

	if (set["ignore_date"] )	
		anc = get_anc_for_date(set,tm_of_data)
		return anc if anc
   	else
		0.upto(set["max_age"]) do | age| 
			#anc = get_anc_for_date(set,tm_of_data - 24*60*60*age)
			anc = get_anc_for_date(set,tm_of_data - age)
			return anc if anc
		end
	end

	raise "Cannot find ancillary files for set #{set["name"]} for #{tm_of_data}"
  end


#get anc for a tm
  def get_anc_for_date(set, tm) 
	#glob the dir with the patern, sort, and take last
	pattern = set["location"] + "/" + tm.strftime(set["filename"])
	Dir.glob(pattern).sort.last
  end

#possibly unknown..
  def get_a_rdr(input_dir, cfg)
	cfg["input"].each do |key,rdr_glob|
		puts("INFO: Looking for #{rdr_glob}")
		rdrs = Dir.glob(input_dir+"/"+rdr_glob)
		return rdrs.first if rdrs.length > 0
	end

      raise "No RDRs found"
  end

#formats the output file
  def format_url(url, tm ) 
	tm.strftime(url)
  end


  def get_time_of_data(input) 
	viirs_rdr = Dir.glob("#{input}/RNSCA-RVIRS*.h5").first
	raise "Can not locate viirs rdr (RNSCA-RVIRS*.h5)"  if !viirs_rdr
	DateTime.strptime(File.basename(viirs_rdr),"RNSCA-RVIRS_npp_d%Y%m%d_t%H%M%S")
  end

  def get_time_of_end_of_data(input)
	File.basename(Dir.glob("#{input}/RNSCA-RVIRS*.h5").first).split("_")[4]
  end


  #not sure how to abstract this out..
  def build_nasa_sdr(input_rdr, cfg)
	command = []
	command << 
	cfg.output.each do |x|
		command << nasa_command_line_item(x)	
	end

  end
end

SnppViirsSdrClamp.run
