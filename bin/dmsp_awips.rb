#!/usr/bin/env ruby
# RTSPS helper..

ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('../..', __FILE__), 'Gemfile')
require 'bundler/setup'
require 'fileutils'
require_relative '../lib/processing_framework'

class DMSPAwipsClamp <  ProcessingFramework::CommandLineHelper
  @description = 'This tool processes DMSP data to L0'
  @config = ProcessingFramework::ConfigLoader.default_path(__FILE__)

  option ['-c', '--config'], 'config', "The config file. Using #{@config} as the default.", default: @config
  option ['-i', '--input'], 'input', 'The input file. ', required: true

  def execute
    conf = ProcessingFramework::ConfigLoader.new(__FILE__)

    output = "#{outdir}"
    outdir += '/' + basename if basename
    basename = File.basename(input) unless basename

    platform =  basename.split('.').first

    working_dir = "#{tempdir}/#{basename}"
    begin
      # make temp space
      FileUtils.rm_r(working_dir) if (File.exist?(working_dir))
      FileUtils.mkdir(working_dir)
      FileUtils.cd(working_dir) do
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
     rescue RuntimeError => e
       puts "Error: #{e.to_s}"
       FileUtils.rm_r(working_dir) if (File.exist?(working_dir))
       exit(-1)
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
    ProcessingFramework::ShellOutHelper.run_shell(". #{cfg['terascan_driver']} ;  #{command}")
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
    ProcessingFramework::ShellOutHelper.run_shell(command)
    command = "gdalwarp #{cfg['awips_conversion']['warp_opts']} -te #{cfg['awips_conversion']['extents']} #{cfg['gdal']['co_opts']} -t_srs #{cfg['awips_conversion']['proj']} #{vis}.stretched.tif #{vis}.302.tif"
    puts("INFO: warping to 302.. #{command}")
    ProcessingFramework::ShellOutHelper.run_shell(command)
  end
end

DMSPAwipsClamp.run
