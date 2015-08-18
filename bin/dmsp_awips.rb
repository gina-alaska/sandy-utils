#!/usr/bin/env ruby
ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('../..', __FILE__), 'Gemfile')
require 'bundler/setup'
require 'fileutils'
require_relative '../lib/processing_framework'

class DMSPAwipsClamp <  ProcessingFramework::CommandLineHelper
  banner 'This tool processes DMSP data to L0'
  default_config 'dmsp_awips'
  
  parameter "INPUT", "The input file"
  parameter "OUTUPT", "The output file"

  def execute
    basename = File.basename(input) unless basename
    working_dir = "#{tempdir}/#{basename}"

    inside(working_dir) do
      infile = check_input(input)
      FileUtils.cp(infile, '.')
      infile = File.basename(infile)
      grided = project(infile, conf)
      tscantifs = to_geotiffs(scale(grided, conf), grided, conf)
      reformat(tscantifs, conf)
      exit(-1)

      # conf["save"].each do |i|
      # Dir.glob(i).each do |x|
      # puts "INFO: Copying #{x} to #{output}"
      # FileUtils.cp(x, output)
      # end
      # end
      # FileUtils.rm_r(working_dir)
    end
  end

  # projects
  def project(infile, cfg)
    command = "fastreg2 master_file=#{get_master(cfg['griding']['master'], cfg)} #{cfg['griding']['opts']} #{infile} #{infile}.fr"
    tscan_run(command, cfg)
    "#{infile}.fr"
  end

  # returns path to master in config
  def get_master(master_basename, cfg)
    File.join(File.expand_path('../../config', __FILE__), cfg['griding']['master'])
  end

  # scales data
  def scale(infile, cfg)
    command = "imscale #{cfg['scaling']['imscale_opts']} #{infile} #{infile}.scale"
    tscan_run(command, cfg)
    "#{infile}.scale"
  end

  # converts from terascan to geotifs
  def to_geotiffs(infile_scaled, infile_grid, cfg)
    command = "#{cfg['tscan_export']['command']} #{cfg['tscan_export']['thermal_opts']} #{infile_grid} #{infile_grid}.thermal.tif"
    tscan_run(command, cfg)
    command = "#{cfg['tscan_export']['command']} #{cfg['tscan_export']['visible_opts']} #{infile_scaled} #{infile_grid}.vis.tif"
    tscan_run(command, cfg)
    { 'thermal' => "#{infile_grid}.thermal.tif", 'vis' => "#{infile_grid}.vis.tif" }
  end

  def tscan_run(command, cfg)
    puts("INFO: Running \". #{cfg['terascan_driver']} ;  #{command}\"")
    shell_out!(". #{cfg['terascan_driver']} ;  #{command}")
  end

  def check_input(infile)
    # needs an ols file
    return infile if (infile.split('.').last == 'ols')
    infiles = Dir.glob(infile + '/*.ols')
    fail("infile #{infile} isn't a ols file, and isn't a directory") unless File.directory?(infile)
    fail("infile #{infile} isn't a ols file, and isn't a directory containing a ols file.") if infile.length == 0
    fail("infile #{infile} is a directory containing several ols file.") if infile.length > 1
    infile.first
  end

  # right now just does vis
  def reformat(tifs, cfg)
    # do vis
    vis = File.basename(tifs['vis'], '.tif')
    command = " #{cfg['awips_conversion']['vis_stretch']} #{vis}.tif #{vis}.stretched.tif"
    puts("INFO: stretching #{command}")
    shell_out!(command)
    command = "gdalwarp #{cfg['awips_conversion']['warp_opts']} -te #{cfg['awips_conversion']['extents']} #{cfg['gdal']['co_opts']} -t_srs #{cfg['awips_conversion']['proj']} #{vis}.stretched.tif #{vis}.302.tif"
    puts("INFO: warping to 302.. #{command}")
    shell_out!(command)
  end
end

DMSPAwipsClamp.run
