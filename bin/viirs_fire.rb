#!/usr/bin/env ruby
# firepoint processing
# Run like:
# modis_mod14.rb -t temp in out
# document describing the fire processing tool: ftp://drl-fs-1.sci.gsfc.nasa.gov/.SOFTWARE/.VFIRE375_SPA_V2.5.1/VFIRE375_2.5.1_SPA_1.7.pdf

ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('../..', __FILE__), 'Gemfile')
require 'bundler/setup'
require 'fileutils'
require_relative '../lib/processing_framework'

class ViirsFireClamp <  ProcessingFramework::CommandLineHelper
  banner 'This tool does iband fire detection processing for viirs'
  default_config 'viirs_fire'

  option ['-m', '--mode'], 'mode', 'mode', default: 'iband'

  parameter 'INPUT', 'Input directory'
  parameter 'OUTPUT', 'Output directory'

  def execute
    exit_with_error("Unknown/unconfigured mode: #{mode}", 19) unless conf['configs'][mode]

    basename = File.basename(input) unless basename

    working_dir = "#{tempdir}/#{basename}"
    inside(working_dir) do
      processing_cfg = conf['configs'][mode]

      result = shell_out!(build_sdr_run_line(input, processing_cfg))

      copy_output(output, processing_cfg['save'])
    end
  end

  def copy_output(output, list)
    # add trailing slash, if needed
    output += '/' if output[-1] != '/'

    FileUtils.mkdir_p(output)  unless (File.exist?(output))
    list.each do |glob|
      Dir.glob(glob).each { |x| FileUtils.cp(x, output) }
    end
  end

  # builds sdr run line
  def build_sdr_run_line(input, cfg)
    command_line = []

    # driver
    command_line << cfg['driver']

    # get the required bands and their input lines
    command_line << get_input_items(input, cfg)

    # get the output txt line
    command_line << get_output_txt_file(input, cfg)

    # get the output hdf file line
    command_line << get_output_hdf_file(input, cfg)

    command_line.join(' ')
  end

  # figures out what the output files should be named like
  def get_output_file_template(input, cfg, data_type, ext)
    # get sample SDR for date..
    sample_sdr = get_an_sdr(input, cfg['input'].first)

    # strip off first and last sections
    # as a reminder, format is like so:
    # SVM16_npp_d20170706_t1941060_e1951040_b00001_c20170725182147627333_gina.h5
    #  A   B   C         D        E        F      G                     H
    # A: file_type
    # B: platform
    # C: date
    # D: start time
    # E: stop time
    # F: orbit number
    # F: date and time the file was created, in YYYMMMDDHHMMSS.SSSSSS format
    # H: source (we set this to gina)

    # plan:
    # keep B - F, append a new G, and add H

    new_file_name = [data_type]
    new_file_name << File.basename(sample_sdr).split('_')[1, 5]
    new_file_name << Time.now.utc.strftime('c%Y%m%d%H%M%S%6N')
    # Fixme possibly: perhaps should be a config item
    new_file_name << 'gina'

    new_file_name.join('_') + '.' + ext
  end

  # gets command line option for text detections file
  def get_output_txt_file(input, cfg)
    [cfg['output_txt'], get_output_file_template(input, cfg, cfg['output_name'], 'txt')].join(' ')
  end

  # gets command line option for hdf5 file
  def get_output_hdf_file(input, cfg)
    [cfg['output_hdf'], get_output_file_template(input, cfg, cfg['output_name'], 'h5')].join(' ')
  end

  # builds up the viirs.svdjlkf /path info required to run the SPAs
  def get_input_items(input, cfg)
    input_items = []
    cfg['input'].each do |item|
      input_items << item
      input_items << get_an_sdr(input, item)
    end

    input_items.join(' ')
  end

  # fetchs the sdr for the particular type - for example "viirs.svm09"
  def get_an_sdr(input, sdr_type)
    band = sdr_type.split('.')[1]
    bands = Dir.glob(input + '/' + band.upcase + '*.h5')
    fail "Could not find SDR for #{sdr_type} in #{input}" if bands.length != 1
    bands.first
  end
end

ViirsFireClamp.run
