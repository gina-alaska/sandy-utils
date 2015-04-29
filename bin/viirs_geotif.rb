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
     # FileUtils.rm_r(working_dir) if (File.exist?(working_dir))
     # FileUtils.mkdir(working_dir)

     FileUtils.cd(working_dir) do
       save_list = []
       # unless (ProcessingFramework::ShellOutHelper.run_shell(command))
       generate_300(processing_cfg, inputdir, processors)
       generate_600(processing_cfg, inputdir, processors)
       processing_cfg['combinations'].each { |x| save_list += generate_image(x) }
       processing_cfg['single_bands'].each { |x| save_list += generate_image_sb(x) }
       save_list += reformat_and_rename_dnb(processing_cfg)
       copy_output(output, save_list)
     end
     FileUtils.rm_r(working_dir)
   rescue RuntimeError => e
     puts "Error: #{e.to_s}"
     FileUtils.rm_r(working_dir) if (File.exist?(working_dir))
     exit(-1)
   end
  end

  # generates i bands
  def generate_300(cfg, i, p)
    command = "#{cfg['polar2grid_driver']} --num-procs #{p} -g #{cfg['igrid']} -d #{i} #{cfg["polar2_grid_options"]} --grid-configs #{get_grid_path(cfg)}"
    fail "ERROR: the command \"#{command}\" failed." unless (ProcessingFramework::ShellOutHelper.run_shell(command))
    # save the i bands
    cleanup("*#{cfg['mgrid']}.tif", /npp_viirs_i_\d\d_\w+/)
  end

  # generates m bands
  def generate_600(cfg, i, p)
    command = "#{cfg['polar2grid_driver']} --num-procs #{p} -g #{cfg['mgrid']} -d #{i} #{cfg["polar2_grid_options"]} --grid-configs #{get_grid_path(cfg)}"
    fail "ERROR: the command \"#{command}\" failed." unless (ProcessingFramework::ShellOutHelper.run_shell(command))

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
    ProcessingFramework::ShellOutHelper.run_shell("gdalbuildvrt -resolution highest -separate #{tmp_name}.vrt #{red} #{green} #{blue}")
    # stretch
    ProcessingFramework::ShellOutHelper.run_shell("gdal_contrast_stretch #{image_hsh["stretch"]} #{tmp_name}.vrt #{tmp_name}.tif")

    if (bands['p'])
      pan = get_band(bands['p'])
      ProcessingFramework::ShellOutHelper.run_shell("gdal_contrast_stretch #{image_hsh["stretch"]} #{pan} #{pan}.tmp")
      ProcessingFramework::ShellOutHelper.run_shell("gdal_landsat_pansharp -ndv 0 -rgb #{tmp_name}.tif -pan #{pan}.tmp -o #{tmp_file}.pan.tif")
      ProcessingFramework::ShellOutHelper.run_shell("rm -v #{pan}.tmp", opts)
      tmp_file =  "#{tmp_file}.pan"
    end

    reformat_geotif("#{tmp_name}.tif", "#{final_file}.tif")
    ProcessingFramework::ShellOutHelper.run_shell("rm -v  #{tmp_name}.vrt #{tmp_name}.tif")
    ProcessingFramework::ShellOutHelper.run_shell("gdal_translate -of png -outsize 1000 1000 #{final_file}.tif #{final_file}.small.png")

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

    ProcessingFramework::ShellOutHelper.run_shell("gdal_contrast_stretch #{image_hsh['stretch']} #{band} #{tmp_name}.tif")
    reformat_geotif(tmp_name + '.tif', final_file + '.tif')
    [final_file + '.tif']
  end

  def reformat_geotif(infile, outfile)
    # gdal opts
    gdal_opts = "-co TILED=YES -co COMPRESS=LZW -a_nodata \"0 0 0\" "
    ProcessingFramework::ShellOutHelper.run_shell("gdal_translate #{gdal_opts} #{infile} #{outfile} ")
    ProcessingFramework::ShellOutHelper.run_shell("add_overviews.rb #{outfile} ")
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

  def generate_filename(f,mapping)
	get_date_of_pass(f).strftime(mapping)
  end 

  def reformat_and_rename_dnb (hsh)
	dnb = Dir.glob(hsh["dnb"]["save"])
	fail("Too many DNB files found.. #{dnb.join(" ")}") if dnb.length > 1
	fail("No DNB files found.. #{dnb.join(" ")}") if dnb.length == 0
	dnb=dnb.first
	outfilename =  generate_filename(dnb, hsh["dnb"]["name"])

	reformat_geotif(dnb, outfilename)
	
	return [outfilename]
  end
end

ViirsGeotifClamp.run
