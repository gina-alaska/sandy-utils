#!/usr/bin/env ruby
# firepoint processing
# Run like:
# mod14_gis.rb -t temp in out

ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('../..', __FILE__), 'Gemfile')
require 'bundler/setup'
require 'fileutils'
require 'date'
require_relative '../lib/processing_framework'

class Mod14GisClamp <  ProcessingFramework::CommandLineHelper
  banner 'This tool does firepoint processing for modis'
  default_config 'mod14_gis'

  option ['-m', '--mode'], 'mode', 'mode', default: 'default'

  parameter 'INPUT', 'Input directory'
  parameter 'OUTPUT', 'Output directory'

  def execute
    exit_with_error("Unknown/unconfigured mode: #{mode}", 19) unless conf['configs'][mode]

    basename = File.basename(input) unless basename

    working_dir = "#{tempdir}/#{basename}"
    inside(working_dir) do
      processing_cfg = conf['configs'][mode]

      # find the fire related files
      fire_hdf = Dir.glob(input + '/*.mod14.hdf').first
      fire_txt =  Dir.glob(input + '/*.mod14.hdf.txt').first
      outputfile_name = File.basename(fire_hdf, 'hdf')

      # File size of 0 means no fires.
      unless (File.size?(fire_txt) == 0)
        fire_txt_reformatted = reformat_fire(fire_txt)

        command = "#{processing_cfg['driver']} #{fire_txt_reformatted} #{outputfile_name}"
        result = shell_out!(command)

        processing_cfg['save'].each do |glob|
          copy_output(output, glob)
        end
      end
    end
  end

  # get platform
  def get_platform(s)
    File.basename(s)[0, 2]
  end

  # get date of mod14 file
  def get_mod14_time(s)
    filename = File.basename(s).split('.')[1, 2].join('.')
    DateTime.strptime(filename, '%Y%m%d.%H%M')
  end

  def reformat_fire(fire_txt)
    # 63.070,166.851,305.8,1.2,1.1,08/07/2016,1509,A,59
    date_of_data = get_mod14_time(fire_txt)
    platform = get_platform(fire_txt)[0].upcase
    File.open('fire_temp', 'w') do |out_fd|
      File.open(fire_txt) do |fd|
        fd.each_line do |ln|
          ln.chomp!
          list = ln.split(',')

          # remove the last two items
          list.pop
          list.pop
          list << date_of_data.strftime('%m/%d/%Y,%H%M')
          list << platform
          # this one does not appear to be used at all.
          list << '100'
          out_fd.puts(list.join(','))
        end
      end
    end

    'fire_temp'
  end
end

Mod14GisClamp.run
