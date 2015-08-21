#!/usr/bin/env ruby
ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('../..', __FILE__), 'Gemfile')
require 'bundler/setup'
require 'fileutils'
require_relative '../lib/processing_framework'

class DMSPAwipsClamp <  ProcessingFramework::CommandLineHelper
  banner 'This tool processes DMSP data to L0'
  default_config 'dmsp_awips'

  parameter 'INPUT', 'The input file'
  parameter 'OUTPUT', 'The output file'
  option ['-d', '--downlink'], 'dowlink', 'The downlink location.', default: 'GLC'

  def execute
    basename = File.basename(input) unless basename
    working_dir = "#{tempdir}/#{basename}"

    #files for awips
    files_to_save = []
    infile = check_input(input)
    #get time of pass
    tm = get_time(infile)

    inside(working_dir) do
      #copy source data ..
      FileUtils.cp(infile, '.')
      infile = File.basename(infile)
      #get plaform
      platform=infile.split(".").first
      grided = project(infile, conf)
      conf['bands'].keys.each do |mode|
        conf['bands'][mode].each do |bd|
          puts("Info: processing band #{bd} (#{mode})")
          out_file = rename(export(grided, conf,  mode, bd, conf['awips']['naming'][bd], 'UAF'), 'OLS', conf['awips']['naming'][bd]['name'], platform, downlink, tm)
          set_time(out_file, tm)
          files_to_save << out_file
        end
      end

      files_to_save.each do |file|
        shell_out!("gzip #{file}")
        File.rename("#{file}.gz", file)
        FileUtils.cp(file, output)
      end
    end
  end

  # projects data onto the grid (the master file)
  def project(infile, cfg)
    command = "fastreg2 master_file=#{get_master(cfg['griding']['master'], cfg)} #{cfg['griding']['opts']} #{infile} #{infile}.fr"
    tscan_run(command, cfg)
    "#{infile}.fr"
  end

  # returns path to master in config
  def get_master(master_basename, cfg)
    File.join(File.expand_path('../../config', __FILE__), cfg['griding']['master'])
  end

  #runs a terascan command
  def tscan_run(command, cfg)
    puts("INFO: Running \". #{cfg['terascan_driver']} ;  #{command}\"")
    shell_out!(". #{cfg['terascan_driver']} ;  #{command}")
  end

  #verifys the input file actually looks like a ols file. shoudl do more verification.
  def check_input(infile)
    # needs an ols file
    return infile if (infile.split('.').last == 'ols')
    infiles = Dir.glob(infile + '/*.ols')
    fail("infile #{infile} isn't a ols file, and isn't a directory") unless File.directory?(infile)
    fail("infile #{infile} isn't a ols file, and isn't a directory containing a ols file.") if infiles.length == 0
    fail("infile #{infile} is a directory containing several ols file.") if infiles.length > 1
    infiles.first
  end

  #gets time of pass
  def get_time(infile)
    DateTime.strptime(File.basename(infile).split('.')[1, 2].join('.') + '+0', '%y%j.%H%M%z')
  end

  #exports data from terascan into a awips compatable form
  def export(fr_file, cfg, mode, band, naming, source)
    command = "#{cfg['export'][mode]} include_vars=#{band} #{fr_file} #{fr_file}.#{band}.float.tif"
    tscan_run(command, cfg)

    shell_out!("#{cfg['scaling'][mode]} #{fr_file}.#{band}.float.tif #{fr_file}.#{band}.awips.tif")
    shell_out!("gdalwarp #{cfg['awips_conversion']['warp_opts']} -te #{cfg['awips_conversion']['extents']} #{cfg['gdal']['co_opts']} -t_srs #{cfg['awips_conversion']['proj']}  #{fr_file}.#{band}.awips.tif  #{fr_file}.#{band}.302.tif")

    shell_out!("gdal_translate #{fr_file}.#{band}.302.tif -of ENVI ./noaa_avhrr_#{band}_203.uint1.8384.7239")
    shell_out!('rm -rfv *.xml *.hdr')

    command = ". #{cfg['polar2grid']['env']} ; python -m polar2grid.awips.awips_netcdf ./noaa_avhrr_#{band}_203.uint1.8384.7239  #{cfg['polar2grid']['grid']} UAF_AWIPS_#{naming['satllite_name']}-AK_1KM \"#{naming['channel']}\" #{source} #{naming['satllite_name']}"
    shell_out!(command)

    "UAF_AWIPS_#{naming['satllite_name']}-AK_1KM"
   end

  # converts from terascan to geotifs - not currently used.
  def to_geotiffs(infile_scaled, infile_grid, cfg)
    command = "#{cfg['tscan_export']['command']} #{cfg['tscan_export']['thermal_opts']} #{infile_grid} #{infile_grid}.thermal.tif"
    tscan_run(command, cfg)
    command = "#{cfg['tscan_export']['command']} #{cfg['tscan_export']['visible_opts']} #{infile_scaled} #{infile_grid}.vis.tif"
    tscan_run(command, cfg)
    { 'thermal' => "#{infile_grid}.thermal.tif", 'vis' => "#{infile_grid}.vis.tif" }
  end

  # renames the awips file to the correct naming scheme
  def rename(fl, sensor, channel, satellite, downlink, tm)
    time_bit =  tm.strftime('%y%m%d_%H%M.%S')
    name = "UAF_AWIPS_#{sensor}-AK_1KM_#{channel}_#{satellite}_#{downlink}_#{time_bit}"
    FileUtils.mv(fl, name)
    name
  end

  # sets time attribute on awips file
  def set_time(fl, tm)
    shell_out!("ncap2 -O -s \"validTime = #{tm.to_time.to_f}\" #{fl} #{fl}")
  end

end

DMSPAwipsClamp.run
