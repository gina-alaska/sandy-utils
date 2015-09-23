#!/usr/bin/env ruby

ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('../..', __FILE__), 'Gemfile')
require 'bundler/setup'
require 'fileutils'
require_relative '../lib/processing_framework'

class MetopL0Clamp < ProcessingFramework::CommandLineHelper
  default_config 'metop_l0'
  banner 'This tool converts MetOp CCSDS to EPS.'

  option ['-s', '--spacecraft_id'], 'spacecraft id', "Spacecraft ID: [M01, M02]", required: true

  parameter "INPUT", 'The input file or directory'
  parameter "OUTPUT", 'The output directory'

  def execute
    exit_with_error("File size to small", 11) if File.stat(input).size < 25000000

    basename = File.basename(input) unless basename
    working_dir = "#{tempdir}/#{basename}"

    inside(working_dir) do
      # RT-STPS XML Assumes you have a data directory for it to write out to
      sourcefile = File.basename(input)
      FileUtils.cp(input, sourcefile)
      sourcefile = uncompress(sourcefile)

      run_ccsds_to_l0(sourcefile)
      rename_to_eps
      generate_mmam_xml
      patch_l0_from_mmam

      copy_output(output, '*Z')
    end
  end

  private

  def run_ccsds_to_l0 sourcefile
    mphr_file = create_mphr

    command = "ccsds_to_l0 -i #{sourcefile} --config-mphr #{mphr_file}"
    shell_out!(command)
  end

  def create_mphr
    File.open("#{spacecraft_id}.mphr", 'w') do |f|
      f.puts "# MetOpizer L0 Production Configuration File"
      f.puts "spacecraft_id=#{spacecraft_id}"
      conf['mphr'].each do |k,v|
        f.puts "#{k}=#{v}"
      end
    end
    "#{spacecraft_id}.mphr"
  end

  def rename_to_eps
    Dir.glob('*.l0').each do |file|
      FileUtils.move(file, generate_eps_name(file))
    end
  end

  def generate_eps_name(file)
    cmd = shell_out!("od --skip-bytes=52 --address-radix=n --read-bytes=67 --format=a --width=67 #{file}  |sed 's/\s//g'")
    cmd.stdout.chomp
  end

  def generate_mmam_xml
    hktm = Dir.glob("HKTM*").first
    shell_out!("mmam-main.exe -pfsl0 #{hktm} mmam.xml.bz2")
    shell_out!("bzip2 -df mmam.xml.bz2")
  end

  def patch_l0_from_mmam
    obtutc = shell_out!('print-mmam-obt-utc.pl mmam.xml')
    Dir.glob("*Z").each do |file|
      shell_out! "patch-level0-from-mmam.exe #{obtutc.stdout.chomp} #{file}"
      FileUtils.rm_f "#{file}.old"
    end
  end
end

MetopL0Clamp.run
