#!/usr/bin/env ruby
ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('../..', __FILE__), 'Gemfile')
require 'bundler/setup'
require 'fileutils'
require_relative '../lib/processing_framework'
require 'date'

class FeederGeotifClamp < ProcessingFramework::CommandLineHelper
  banner 'This tool takes MODIS and VIIRS data and makes geotifs intended for feeder.'
  default_config 'feeder_geotif'

  option ['-m', '--mode'], 'mode', 'The mode to use.', required: true

  parameter 'INPUT', 'The input directory'
  parameter 'OUTPUT', 'The output directory'

  def execute
    exit_with_error("Unknown/unconfigured mode #{mode}", 19) unless conf['configs'][mode]
    processing_cfg = conf['configs'][mode]

    basename = File.basename(input) unless basename
    working_dir = "#{tempdir}/#{basename}"

    inside(working_dir) do
      save_list = []
      # single
      processing_cfg['single'].each do |single|
        begin
          save_list << generate_image_sb(single, input, processing_cfg)
        rescue RuntimeError => e
          puts("INFO: skipping #{single['title']}, band not found. #{e.to_s}")
        end
      end
      # combinations
      processing_cfg['combinations'].each do |rgb|
        begin
          save_list << generate_image(rgb, input, processing_cfg)
        rescue RuntimeError => e
          puts("INFO: skipping #{rgb['title']}, bands not found. #{e.to_s}")
        end
      end
      # specials
      if (processing_cfg['extras'])
        processing_cfg['extras'].each do |rgb|
          begin
            save_list << generate_image_extras(rgb, input, processing_cfg)
          rescue RuntimeError => e
            puts("INFO: skipping #{rgb['title']}, bands not found. #{e.to_s}")
          end
        end
      end

      save_list.each do |geotif|
        copy_output(output, geotif)
      end
    end
  end

  def band_mapper(band, cfg)
    cfg['mapper'][band]
  end

  # locates correct file for a band generated with polar_to_grid
  # should throw an exception if the file isn't found, more than one is found, or the band isn't in the mapping
  def get_band(input_dir, band, cfg)
    file_name_pattern = band_mapper(band, cfg)
    raise "Couldn't find band mapping for #{band}" unless file_name_pattern
    puts("INFO: Looking for #{file_name_pattern}")
    band_file = Dir.glob(input_dir + '/' + file_name_pattern)
    raise "Too many bands found (#{band_file.join(',')} for band #{color}" if (band_file.length > 1)
    raise "No bands found for band #{band}" if band_file.empty?
    band_file.first
  end

  ##
  # Generates multi-band images.
  def generate_image(image_hsh, input, cfg, basename = nil)
    bands = image_hsh['bands']

    red = get_band(input, bands['r'], cfg)
    green = get_band(input, bands['g'], cfg)
    blue = get_band(input, bands['b'], cfg)

    unless basename
      # determine the correct naming scheme... use the "Red" file to figure this out.
      # naming format is npp_viirs_m_04_20150326_214512_alaska_300.tif like.
      date_of_pass = get_date_of_pass(red)
      basename = date_of_pass.strftime(image_hsh['name'])
    end
    final_file = basename
    tmp_name = basename + '.tmp.vrt'

    # make vrt
    shell_out!("gdalbuildvrt -resolution highest -separate #{tmp_name} #{red} #{green} #{blue}",clean_environment: false)

    if (bands['p'])
      pan = get_band(input, bands['p'], cfg)
      shell_out!("gdal_landsat_pansharp -ndv 0 -rgb #{tmp_name} -pan #{pan} -o #{tmp_name}.pan.tif",clean_environment: false)
      tmp_file = "#{tmp_name}.pan.tif"
    end

    reformat_geotif(tmp_name.to_s, "#{final_file}.tif")
    shell_out!("rm -vf #{tmp_name} #{tmp_name}.pan.tif")
    shell_out!("gdal_translate -of png -outsize 5% 5% #{final_file}.tif #{final_file}.small.png",clean_environment: false)

    ["#{final_file}.tif", "#{final_file}.small.png"]
  end

  ##
  # Generates specials
  def generate_image_extras(image_hsh, input, cfg, basename = nil)
    bands = image_hsh['bands']

    red = get_band(input, bands['r'], cfg)
    green = get_band(input, bands['g'], cfg)
    blue = get_band(input, bands['b'], cfg)

    unless basename
      # determine the correct naming scheme... use the "Red" file to figure this out.
      # naming format is npp_viirs_m_04_20150326_214512_alaska_300.tif like.
      date_of_pass = get_date_of_pass(red)
      basename = date_of_pass.strftime(image_hsh['name'])
    end

    shell_out!("#{image_hsh['tool']} --red #{red} --green #{green} --blue #{blue} #{basename}.tif", clean_environment: true)
    shell_out!("add_overviews.rb #{basename}.tif", clean_environment: true)
    shell_out!("gdal_translate -of png -outsize 5% 5% #{basename}.tif #{basename}.small.png", clean_environment: false)

    ["#{basename}.tif", "#{basename}.small.png"]
  end

  ##
  # Generates singled badded images.
  def generate_image_sb(image_hsh, input, cfg, basename = nil)
    # options for stretching

    band = get_band(input, image_hsh['band'], cfg)

    unless basename
      # determine the correct naming scheme... use the "Red" file to figure this out.
      # naming format is npp_viirs_m_04_20150326_214512_alaska_300.tif like.
      date_of_pass = get_date_of_pass(band)
      basename = date_of_pass.strftime(image_hsh['name'])
    end

    final_file = basename
    tmp_name = basename + '.tmp'

    reformat_geotif(band, final_file + '.tif')
    shell_out!("gdal_translate -of png -outsize 5% 5% #{final_file}.tif #{final_file}.small.png",clean_environment: false )
    [final_file + '.tif', final_file + '.small.png']
  end

  def reformat_geotif(infile, outfile)
    # gdal opts
    gdal_opts = "-co TILED=YES -co COMPRESS=DEFLATE -co ZLEVEL=9 -co NUM_THREADS=ALL_CPUS -a_nodata \"0 0 0\""
    shell_out!("gdal_translate #{gdal_opts} #{infile} #{outfile}",clean_environment: false)
    shell_out!("add_overviews.rb #{outfile}",clean_environment: false)
  end

  # get date of pass, from p2g style naming
  def get_date_of_pass(f)
    if (f.downcase.include?("gcom"))
	puts File.basename(f).split('.')[1, 2].join('_')
	return DateTime.strptime(File.basename(f).split('.')[1, 2].join('_'), '%Y%m%d_%H%M')
    else

	if (f.downcase.include?("_alaska_gm_"))
	  return DateTime.strptime(File.basename(f).split('_')[-5, 2].join('_'), '%Y%m%d_%H%M%S')
	else
    	  return DateTime.strptime(File.basename(f).split('_')[-4, 2].join('_'), '%Y%m%d_%H%M%S')
	end
    end
  end

  # generate output filename
  def generate_filename(f, mapping)
    get_date_of_pass(f).strftime(mapping)
  end
end

FeederGeotifClamp.run
