#!/usr/bin/env ruby
# Tool to generate geotif stuff for viirs
#
# for more info see: viirs_geotif.rb --help

ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('../..', __FILE__), 'Gemfile')
require 'bundler/setup'
require 'fileutils'
require_relative '../lib/processing_framework'

class ViirsGeotifClamp <  ProcessingFramework::CommandLineHelper
  @description = 'This tool takes VIIRS data and makes geotifs .'
  @config = ProcessingFramework::ConfigLoader.default_path(__FILE__)
  @conf = ProcessingFramework::ConfigLoader.new(__FILE__)

  option ['-c', '--config'], 'config', "The config file. Using #{@config} as the default.", default: @config
  option ['-i', '--inputdir'], 'inputdir', 'The input directory. ', required: true
  option ['-m', '--mode'], 'mode', "The mode to use #{@conf['configs'].keys.join(',')}.", default: 'default'
  option ['-p', '--processors'], 'processors', 'The number of processors to use for processing.',  environment_variable: 'PROCESSING_NUMBER_OF_CPUS', default: @conf['limits']['processor']

  def execute
    conf = ProcessingFramework::ConfigLoader.new(__FILE__)

    output = "#{outdir}"
    outdir += '/' + basename if basename
    basename = File.basename(inputdir) unless basename

    # check mode
    fail "Unknown/unconfigured mode #{mode}" unless conf['configs'][mode]
    processing_cfg = conf['configs']["#{mode}"]

    working_dir = "#{tempdir}/#{basename}"

    begin
     # make temp space
     FileUtils.rm_r(working_dir) if (File.exist?(working_dir))
     FileUtils.mkdir(working_dir)

     FileUtils.cd(working_dir) do
       #unless (ProcessingFramework::ShellOutHelper.run_shell(command))
	generate_300(processing_cfg, inputdir, processors)
        generate_600(processing_cfg, inputdir, processors)
     end
     FileUtils.rm_r(working_dir)
   rescue RuntimeError => e
     puts "Error: #{e.to_s}"
     FileUtils.rm_r(working_dir) if (File.exist?(working_dir))
     exit(-1)
   end
  end

  #generates i bands
  def generate_300(cfg, i, p)
      command = "#{cfg["polar2grid_driver"]} --num-procs #{p} -g #{cfg["igrid"]} -d #{i} --grid-configs #{get_grid_path(cfg)}"
      fail "ERROR: the command \"#{command}\" failed." if (!ProcessingFramework::ShellOutHelper.run_shell(command))
      #save the i bands
      cleanup("*#{cfg["mgrid"]}.tif", /npp_viirs_i_\d\d_\w+/)
  end

  #generates m bands
  def generate_600(cfg, i, p)
      command = "#{cfg["polar2grid_driver"]} --num-procs #{p} -g #{cfg["mgrid"]} -d #{i} --grid-configs #{get_grid_path(cfg)}"
      fail "ERROR: the command \"#{command}\" failed." if (!ProcessingFramework::ShellOutHelper.run_shell(command))

      #save the m bands and the dnb band.
      cleanup("*#{cfg["mgrid"]}.tif", /npp_viirs_m_\d\d_\w+|npp_viirs_dnb_\w+/)
  end

  #gets path to the grid file.
  def get_grid_path(cfg)
	 File.join(File.expand_path('../..', __FILE__), cfg["grid_file"])
  end

  #takes a glob, and deletes files that don't math the RE
  def cleanup(glob, pattern)
    Dir.glob(glob).each do |x|
       if (pattern.match(x) ) 
          puts "Info: Saving:#{x}"
       else
          puts "Info: Deleting:#{x}"
          FileUtils.rm(x)
       end
    end
  end

  def get_band(color, opts)
        return get_band_pytrol(color) if (opts[:pytrol])
        get_band_polar_to_grid(color)
  end

  #locates correct file for a band generated with polar_to_grid
  def get_band_polar_to_grid(band )
  color = band_mapper(band)
  puts ("Looking for npp_viirs_#{color}*.tif")
  band = Dir.glob("npp_viirs_#{color}*.tif")
  raise(RuntimeError, "Too many bands found (#{band.join(",")} for band #{color}") if (band.length > 1)
  raise(RuntimeError,"No bands found for band #{color}") if (band.length == 0)
  band.first
end



#maps bands from MXX IXX formats to the i_xx/m_xx format 
def band_mapper(band)
        case band[0]
                when "M"
                        return "m_" + band[1,2]
                when "I"
                        return "i_" + band[1,2]
                when "D"
                        return "_dnb_"
        end
end


  def generate_image(image_hsh)
contrast_options = "-ndv '0.99995..1' -ndv 0.0 -linear-stretch 128 50 -outndv 0 "
gdal_opts = "-co TILED=YES -co COMPRESS=LZW -a_nodata \"0 0 0\" "

FileUtils.cd(ARGV[0]) do
  tmp_name = opts[:red] + "_" + opts[:green] + "_" + opts[:blue] + "_" + ".tmp"
  red = get_band(opts[:red], opts)
  green = get_band(opts[:green], opts)
  blue = get_band(opts[:blue], opts)
  runner("gdalbuildvrt -resolution highest -separate #{tmp_name}.vrt #{red} #{green} #{blue}", opts)
  runner("gdal_contrast_stretch #{contrast_options} #{tmp_name}.vrt #{tmp_name}.tif", opts)

  final_file = ""
  temp_file = ""
  if ( opts[:pan] != "none" )
    temp_file = tmp_name + "_" + opts[:pan]
    final_file = File.basename(get_band(opts[:pan], opts)).split("_").first + "_" + opts[:red] + "_" + opts[:green] + "_" + opts[:blue] + "_" + opts[:pan]
    pan = get_band(opts[:pan],opts)
    runner("gdal_contrast_stretch #{contrast_options} #{pan} #{pan}.tmp", opts)
    runner("gdal_landsat_pansharp -ndv 0 -rgb #{tmp_name}.tif -pan #{pan}.tmp -o #{temp_file}.tif", opts)
    runner("rm -v #{pan}.tmp", opts)
  else
    temp_file = tmp_name 
    final_file = File.basename(get_band(opts[:red],opts)).split("_").first + "_" + opts[:red] + "_" + opts[:green] + "_" + opts[:blue]
  end
  runner("gdal_translate #{gdal_opts} #{temp_file}.tif #{final_file}.tif ", opts)
  runner("add_overviews.rb #{final_file}.tif ", opts)
  runner("rm -v #{temp_file}.tif #{tmp_name}.vrt #{tmp_name}.tif", opts)
  runner("gdal_translate -of png -outsize 1000 1000 #{final_file}.tif #{final_file}.small.png", opts)
end
end




end

ViirsGeotifClamp.run
