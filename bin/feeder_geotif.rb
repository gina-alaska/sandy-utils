#!/usr/bin/env ruby
ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('../..', __FILE__), 'Gemfile')
require 'bundler/setup'
require 'fileutils'
require_relative '../lib/processing_framework'

class FeederGeotifClamp <  ProcessingFramework::CommandLineHelper
  banner 'This tool takes MODIS and VIIRS data and makes geotifs intended for feeder.'
  default_config 'feeder_geotif'

  option ['-m', '--mode'], 'mode', 'The mode to use.', default: 'default'

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
        save_list << generate_image_sb(single, input,processing_cfg)
      end
      # combinations
      processing_cfg['combinations'].each do |rgb|
	save_list << generate_image(rgb, input, processing_cfg)
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
  def get_band(input_dir, band, cfg)
    file_name_pattern = band_mapper(band, cfg)
    fail "Couldn't find band mapping for #{band}" if !file_name_pattern 
    puts("Looking for #{file_name_pattern}")
    band = Dir.glob(input_dir + '/' + file_name_pattern)
    fail "Too many bands found (#{band.join(',')} for band #{color}" if (band.length > 1)
    fail "No bands found for band #{color}" if (band.length == 0)
    band.first
  end

  ##
  # Generates multi-band images.
  def generate_image(image_hsh, input, cfg, basename = nil)
    bands = image_hsh['bands']

    red = get_band(input,bands['r'],cfg)
    green = get_band(input,bands['g'],cfg)
    blue = get_band(input,bands['b'],cfg)

    unless (basename)
      # determine the correct naming scheme... use the "Red" file to figure this out.
      # naming format is npp_viirs_m_04_20150326_214512_alaska_300.tif like.
      date_of_pass = DateTime.strptime(red.split('_')[-4, 2].join('_'), '%Y%m%d_%H%M%S')
      basename = date_of_pass.strftime(image_hsh['name'])
    end
    final_file = basename
    tmp_name = basename + '.tmp.vrt'

    puts tmp_name

    # make vrt
    shell_out!("gdalbuildvrt -resolution highest -separate #{tmp_name} #{red} #{green} #{blue}")

    if (bands['p'])
      pan = get_band(input,bands['p'],cfg)
      shell_out!("gdal_landsat_pansharp -ndv 0 -rgb #{tmp_name} -pan #{pan} -o #{tmp_name}.pan.tif")
      tmp_file =  "#{tmp_name}.pan.tif"
    end

    reformat_geotif("#{tmp_name}", "#{final_file}.tif")
    shell_out!("rm -vf #{tmp_name} #{tmp_name}.pan.tif")
    shell_out!("gdal_translate -of png -outsize 5% 5% #{final_file}.tif #{final_file}.small.png")

    ["#{final_file}.tif", "#{final_file}.small.png"]
  end

  ##
  # Generates singled badded images.
  def generate_image_sb(image_hsh, input, cfg, basename = nil)
    # options for stretching

    band = get_band(input,image_hsh['band'],cfg)

    unless (basename)
      # determine the correct naming scheme... use the "Red" file to figure this out.
      # naming format is npp_viirs_m_04_20150326_214512_alaska_300.tif like.
      date_of_pass = DateTime.strptime(File.basename(band).split('_')[-4, 2].join('_'), '%Y%m%d_%H%M%S')
      basename = date_of_pass.strftime(image_hsh['name'])
    end

    final_file = basename
    tmp_name = basename + '.tmp'

    reformat_geotif(band, final_file + '.tif')
    [final_file + '.tif']
  end

  def reformat_geotif(infile, outfile)
    # gdal opts
    gdal_opts = "-co TILED=YES -co COMPRESS=DEFLATE -co ZLEVEL=9 -co PREDICTOR=2 -a_nodata \"0 0 0\""
    shell_out!("gdal_translate #{gdal_opts} #{infile} #{outfile}")
    shell_out!("add_overviews.rb #{outfile}")
  end

  def copy_output(output, list)
    # add trailing slash, if needed
    output += '/' if output[-1] != '/'

    FileUtils.mkdir_p(output)  unless (File.exist?(output))
    list.each { |x|  FileUtils.cp(x, output) }
  end

  def get_date_of_pass(f)
    DateTime.strptime(f.split('_')[4, 2].join('_'), '%Y%m%d_%H%M%S')
  end

  def generate_filename(f, mapping)
    get_date_of_pass(f).strftime(mapping)
  end

  def reformat_and_rename_dnb(hsh)
    dnb = Dir.glob(hsh['dnb']['save'])
    fail("Too many DNB files found.. #{dnb.join(' ')}") if dnb.length > 1
    fail("No DNB files found.. #{dnb.join(' ')}") if dnb.length == 0
    dnb = dnb.first
    outfilename =  generate_filename(dnb, hsh['dnb']['name'])

    reformat_geotif(dnb, outfilename)

    [outfilename]
  end
end

FeederGeotifClamp.run
