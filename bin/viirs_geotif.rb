#!/usr/bin/env ruby
ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('../..', __FILE__), 'Gemfile')
require 'bundler/setup'
require 'fileutils'
require_relative '../lib/processing_framework'

class ViirsGeotifClamp <  ProcessingFramework::CommandLineHelper
  banner 'This tool takes VIIRS data and makes geotifs .'
  default_config 'viirs_geotif'
  
  option ['-m', '--mode'], 'mode', "The mode to use.", default: 'default'
  option ['-p', '--processors'], 'processors', 'The number of processors to use for processing.',  environment_variable: 'PROCESSING_NUMBER_OF_CPUS', default: @conf['limits']['processor']

  parameter "INPUT", "The input directory"
  parameter "OUTPUT", "The output directory"

  def execute
    exit_with_error("Unknown/unconfigured mode #{mode}", 19) unless conf['configs'][mode]
    processing_cfg = conf['configs'][mode]

    basename = File.basename(input) unless basename
    working_dir = "#{tempdir}/#{basename}"

    inside(working_dir) do
      save_list = []
      generate_300(processing_cfg, input, processors)
      generate_600(processing_cfg, input, processors)
      processing_cfg['combinations'].each { |x| save_list += generate_image(x) }
      processing_cfg['single_bands'].each { |x| save_list += generate_image_sb(x) }
      save_list += reformat_and_rename_dnb(processing_cfg)
      copy_output(output, save_list)
    end
  end

  # generates i bands
  def generate_300(cfg, i, p)
    command = "#{cfg['polar2grid_driver']} --num-procs #{p} -g #{cfg['igrid']} -d #{i} #{cfg['polar2_grid_options']} --grid-configs #{get_grid_path(cfg)}"
    result = shell_out!(command)
    exit_with_error("#{command} failed.", 12) if result.status != 0
    # save the i bands
    cleanup("*#{cfg['mgrid']}.tif", /npp_viirs_i_\d\d_\w+/)
  end

  # generates m bands
  def generate_600(cfg, i, p)
    command = "#{cfg['polar2grid_driver']} --num-procs #{p} -g #{cfg['mgrid']} -d #{i} #{cfg['polar2_grid_options']} --grid-configs #{get_grid_path(cfg)}"
    result = shell_out!(command)
    exit_with_error("#{command} failed.", 12) if results.status != 0
    # save the m bands and the dnb band.
    cleanup("*#{cfg['mgrid']}.tif", /npp_viirs_m_\d\d_\w+|npp_viirs_dnb_\w+/)
  end

  # gets path to the grid file.
  def get_grid_path(cfg)
    File.join(File.expand_path('../..', __FILE__), cfg['grid_file'])
  end

  # takes a glob, and deletes files that don't math the RE
  def cleanup(glob, pattern)
    Dir.glob(glob).each do |x|
      if (pattern.match(x))
        puts "Info: Saving:#{x}"
      else
        puts "Info: Deleting:#{x}"
        FileUtils.rm(x)
      end
    end
  end

  # locates correct file for a band generated with polar_to_grid
  def get_band(band)
    color = band_mapper(band)
    puts("Looking for npp_viirs_#{color}*.tif")
    band = Dir.glob("npp_viirs_#{color}*.tif")
    fail("Too many bands found (#{band.join(',')} for band #{color}") if (band.length > 1)
    fail("No bands found for band #{color}") if (band.length == 0)
    band.first
  end

  # maps bands from MXX IXX formats to the i_xx/m_xx format
  def band_mapper(band)
    case band[0]
    when 'M'
      return 'm_' + band[1, 2]
    when 'I'
      return 'i_' + band[1, 2]
    when 'D'
      return '_dnb_'
    end
  end

  ##
  # Generates multi-band images.
  def generate_image(image_hsh, basename = nil)
    bands = image_hsh['bands']

    red = get_band(bands['r'])
    green = get_band(bands['g'])
    blue = get_band(bands['b'])

    unless (basename)
      # determine the correct naming scheme... use the "Red" file to figure this out.
      # naming format is npp_viirs_m_04_20150326_214512_alaska_300.tif like.
      date_of_pass = DateTime.strptime(red.split('_')[4, 2].join('_'), '%Y%m%d_%H%M%S')
      basename = date_of_pass.strftime(image_hsh['name'])
    end
    final_file = basename
    tmp_name = basename + '.tmp'

    puts tmp_name

    # make vrt
    shell_out!("gdalbuildvrt -resolution highest -separate #{tmp_name}.vrt #{red} #{green} #{blue}")
    # stretch
    shell_out!("gdal_contrast_stretch #{image_hsh['stretch']} #{tmp_name}.vrt #{tmp_name}.tif")

    if (bands['p'])
      pan = get_band(bands['p'])
      shell_out!("gdal_contrast_stretch #{image_hsh['stretch']} #{pan} #{pan}.tmp")
      shell_out!("gdal_landsat_pansharp -ndv 0 -rgb #{tmp_name}.tif -pan #{pan}.tmp -o #{tmp_file}.pan.tif")
      shell_out!("rm -v #{pan}.tmp", opts)
      tmp_file =  "#{tmp_file}.pan"
    end

    reformat_geotif("#{tmp_name}.tif", "#{final_file}.tif")
    shell_out!("rm -v #{tmp_name}.vrt #{tmp_name}.tif")
    shell_out!("gdal_translate -of png -outsize 1000 1000 #{final_file}.tif #{final_file}.small.png")

    ["#{final_file}.tif", "#{final_file}.small.png"]
  end

  ##
  # Generates singled badded images.
  def generate_image_sb(image_hsh, basename = nil)
    # options for stretching

    band = get_band(image_hsh['band'])

    unless (basename)
      # determine the correct naming scheme... use the "Red" file to figure this out.
      # naming format is npp_viirs_m_04_20150326_214512_alaska_300.tif like.
      date_of_pass = DateTime.strptime(band.split('_')[4, 2].join('_'), '%Y%m%d_%H%M%S')
      basename = date_of_pass.strftime(image_hsh['name'])
    end

    final_file = basename
    tmp_name = basename + '.tmp'

    shell_out!("gdal_contrast_stretch #{image_hsh['stretch']} #{band} #{tmp_name}.tif")
    reformat_geotif(tmp_name + '.tif', final_file + '.tif')
    [final_file + '.tif']
  end

  def reformat_geotif(infile, outfile)
    # gdal opts
    gdal_opts = "-co TILED=YES -co COMPRESS=LZW -a_nodata \"0 0 0\""
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

ViirsGeotifClamp.run
