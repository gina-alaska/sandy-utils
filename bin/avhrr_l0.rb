#!/usr/bin/env ruby
ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('../..', __FILE__), 'Gemfile')
require 'bundler/setup'
require 'fileutils'
require_relative '../lib/processing_framework'

class AVHRRL0Clamp < ProcessingFramework::CommandLineHelper
  banner 'This tool processes AVHRR data to L0'
  default_config 'avhrr_l0'

  parameter 'INPUT', 'The input file'
  parameter 'OUTPUT', 'The output directory'

  def execute
    basename = File.basename(input) unless basename
    platform = basename.split('.').first

    working_dir = "#{tempdir}/#{basename}"
    inside(working_dir) do
      sourcefile = File.basename(input)
      FileUtils.cp(input, sourcefile)
      sourcefile = uncompress(sourcefile)

      year = Time.now.strftime('%Y')
      command = "hrptin #{conf['opts']} tape_device=./#{sourcefile} pass_year=#{year} ."
      shell_out!(command)

      # check date
      check_date(sourcefile)

      conf['save'].each do |pattern|
        copy_output(output, pattern)
      end
    end
  end


  ##
  # This checked to see if the data of the processed data is within 10 minutes of the source timestamp.
  # and is not more than 2 days into the future. 
  
  def check_date(source_file)
    avhrr_file = Dir.glob('*.avhrr').first
    raise 'No avhrr file found, the processing must have failed' unless avhrr_file


    #Catch exception in case of wierd dates, like for example "n19.17366.2352.avhrr"
    begin
      # time of processed data
      time_of_data = get_time(avhrr_file)
      # time of recieved pass
      time_of_source = get_time(source_file)
    rescue ArgumentError => e
    	puts("ERROR: An error occured parsing the source or processed filenames.")
	puts("ERROR: \t#{e.to_s}")
        raise 'Processed data has a strange time'
    end

    #if the time of the processed data and the source data is different by more than 10 minutes, report as bad
    if ((time_of_data - time_of_source) > 600)
      puts('ERROR: Processed data seems to have a strange time')
      puts("ERROR: Source: #{source_file}, time => #{time_of_source.to_s}")
      puts("ERROR: Data:  #{avhrr_file}, time => #{time_of_data.to_s}")
      raise 'Processed data has a strange time'
    end

    #If the date of the data is more than 2 days in the future, report as bad. 
    if ((time_of_data - DateTime.now ) > 2*24*60*60)
      puts('ERROR: Processed data is in the future')
      puts("ERROR: Source: #{source_file}, time => #{time_of_source.to_s}")
      puts("ERROR: Data:  #{avhrr_file}, time => #{time_of_data.to_s}")
      raise 'Processed data has a date in the future'
    end

  end

  # returns date of avhrr file.
  def get_time(infile)
    DateTime.strptime(File.basename(infile).split('.')[1, 2].join('.') + '+0', '%y%j.%H%M%z')
  end
end

AVHRRL0Clamp.run
