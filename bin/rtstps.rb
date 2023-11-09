#!/usr/bin/env ruby
ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('..', __dir__), 'Gemfile')
require 'bundler/setup'
require 'fileutils'
require_relative '../lib/processing_framework'


# single rtstps output file
class Rtstps
  require 'date'
  TIME_FIDDLE = 120
  def initialize(item)
    get_date(item)
    @path = item
  end

  def get_date(item)
    case File.basename(item)
    # RNSCA-RVIRS_npp_d20230803_t2113540_e2128075_b00001_c20230803212723278000_all-_dev.h5
    when /[A-Z\-]+_[0-9a-z]+_d\d{8}_t\d{7}_e\d{7}_b\d{5}_c\d{20}_[a-zA-Z0-9._\-]+/
      bits = /[A-Z\-]+_([0-9a-z]+)_d(\d{8})_t(\d{7})_e(\d{7})_b\d{5}_c(\d{20})_[a-zA-Z0-9._\-]+/.match(File.basename(item))
      @start_dt = parse_date(bits[2] + bits[3], '%Y%m%d%H%M')
      @end_dt = parse_date(bits[2] + bits[4], '%Y%m%d%H%M')
      @create_dt = parse_date(bits[5], '%Y%m%d%H%M')
      @platform = bits[1]
    when /\w{22}\d{14}\.PDS/ then true
                                  # P1570560AAAAAAAAAAAAAAyyDDDhhmmss001.PDS
                                  bits = /(\w{22})(\d{11})/.match(File.basename(item))
                                  @start_dt = parse_date(bits[2], '%y%j%H%M')
                                  @end_dt = nil
                                  @create_dt = nil
                                  @platform = nil
    else
      false
    end
  end

  def to_s
    if @platform
      puts("RDR: #{@platform} / #{@start_dt} : #{@path}")
    else
      puts("PDS: #{@start_dt}")
    end
  end

  def near?(dt, platform)
    # puts("INFO: Comparing #{dt}:#{platform} with #{to_s}")
    return false if platform_mapper(platform) != @platform
    return false if dt < @start_dt - TIME_FIDDLE || dt > @start_dt + TIME_FIDDLE

    true
  end

  def platform_mapper(platform)
    mapper = { 'noaa21' => 'j02', 'snpp' => 'npp', 'noaa20' => 'j01' }
    mapper[platform.downcase] || platform
  end

  def parse_date(filename, pattern)
    DateTime.strptime(filename, pattern).to_time
  end

  attr_reader :path

  class << self
    def item?(x)
      case File.basename(x)
      # RNSCA-RVIRS_npp_d20230803_t2113540_e2128075_b00001_c20230803212723278000_all-_dev.h5
      when /[A-Z\-]+_[0-9a-z]+_d\d{8}_t\d{7}_e\d{7}_b\d{5}_c\d{20}_[a-zA-Z0-9._\-]+/ then true

      # P1590000AAAAAAAAAAAAAS23215170936000.PDS
      when /\w{22}\d{14}\.PDS/ then true
      else
        false
      end
    end
  end
end

# a set of rtstps files
class RtstpsSet
  def initialize(list)
    @list = []
    list.each do |item|
      rtstps = Rtstps.new(item)
      @list << rtstps if rtstps
    end
  end

  def find(start_dt, platform)
    matches = []
    @list.each do |rdr|
      matches << rdr if rdr.near?(start_dt, platform)
    end
    matches
  end
end

class RtstpsClamp < ProcessingFramework::CommandLineHelper
  require 'date'
  include ProcessingFramework::CompressHelper
  banner 'This tool does CCSDS unpacking using Rtstps for SNPP, AQUA, and TERRA.'
  default_config 'rtstps'

  option ['-c', '--config'], 'config', "The config file. Using #{@config} as the default.", default: @config
  option ['-p', '--platform'], 'platform', 'The platform this data is from (npp, a1, t1)', attribute_name: :platform_type
  option ['-f', '--facility'], 'facility', 'The facility the data was aquired at.', attribute_name: :facility
  parameter 'INPUT', 'The input file'
  parameter 'OUTPUT', 'The output directory'

  def get_date(path)
    details = parse_name(File.basename(path))
    puts details.join(' ')
    details[1]
  end

  def parse_date(filename, pattern)
    DateTime.strptime(filename, pattern).to_time
  end

  def parse_name(filename)
    name = filename.downcase
    case name
    when /^npp.\d{5}.\d{4}/ then      ['snpp', parse_date(name, 'npp.%y%j.%H%M')]
    when /^npp.\d{8}.\d{4}/ then      ['snpp', parse_date(name, 'npp.%Y%m%d.%H%M')]
    when /^a1.\d{5}.\d{4}/ then       ['aqua', parse_date(name, 'a1.%y%j.%H%M')]
    when /^aqua.\d{8}.\d{4}/ then     ['aqua', parse_date(name, 'aqua.%Y%m%d.%H%M')]
    when /^t1.\d{5}.\d{4}/ then       ['terra', parse_date(name, 't1.%y%j.%H%M')]
    when /^terra.\d{8}.\d{4}/ then    ['terra', parse_date(name, 'terra.%Y%m%d.%H%M')]
    when /^tp\d{13}.metop-b.dat/ then ['metop-b', parse_date(name, 'tp%Y%j%H%M')]
    when /^tp\d{13}.metop-c.dat/ then ['metop-c', parse_date(name, 'tp%Y%j%H%M')]
    when /^n15/ then                  ['noaa15', parse_date(name, 'n15.%y%j.%H%M')]
    when /^n18/ then                  ['noaa18', parse_date(name, 'n18.%y%j.%H%M')]
    when /^n19/ then                  ['noaa19', parse_date(name, 'n19.%y%j.%H%M')]
    when /^noaa18/ then               ['noaa18', parse_date(name, 'noaa18.%Y%m%d.%H%M')]
    when /^noaa19/ then               ['noaa19', parse_date(name, 'noaa19.%Y%m%d.%H%M')]
    when /^jpss1.\d{8}.\d{4}/ then    ['noaa20', parse_date(name, 'jpss1.%Y%m%d.%H%M')]
    when /^j1.\d{5}.\d{4}/ then       ['noaa20', parse_date(name, 'j1.%y%j.%H%M')]
    when /^jpss2.\d{8}.\d{4}/ then    ['noaa21', parse_date(name, 'jpss2.%Y%m%d.%H%M')]
    when /^j2.\d{5}.\d{4}/ then       ['noaa21', parse_date(name, 'j2.%y%j.%H%M')]
    when /^gcom-w1.\d{8}.\d{4}/ then  ['gcom-w', parse_date(name, 'gcom-w1.%Y%m%d.%H%M')]
    # TODO:  DMSP
    else ['unknown', Time.now]
    end
  end

  def execute
    # Check platform
    basename ||= File.basename(input)

    platform = platform_type
    platform ||= basename.split('.').first

    exit_with_error("Unknown platform: #{platform}", 19) unless conf['configs'][platform]

    working_dir = "#{tempdir}/#{basename}"

    #get date of pass.
    pass_date = get_date(input)

    ##
    # If facility is set, check to see if data is available - if so use that
    if facility
      rdr_list = Dir.glob(conf['source'][facility] + '/*.h5')
      rdrs = RtstpsSet.new(rdr_list).find(pass_date, platform)
      # Need at least 3 files rdrs, anything less then there is likely a problem
      if rdrs.length >= 3
        system('mkdir', '-p', output)
        puts('INFO: Using pre-generated RDRs')
        rdrs.each do |rdr|
          puts("INFO: Using #{rdr.path}")
          system('/usr/bin/cp', rdr.path, output + '/')
        end
        return
      end
    end

    ##
    # Process as normal, the output isn't already available.

    inside(working_dir) do
      # RT-STPS XML Assumes you have a data directory for it to write out to
      FileUtils.mkdir('data')
      sourcefile = File.basename(input)
      FileUtils.cp(input, sourcefile)
      sourcefile = uncompress(sourcefile)

      inside("#{working_dir}/data") do
        # RT-STPS Expects to write to ../data
        #  cd into data so that ../data exists
        # New versions of RT-STPS require a leapsec.dat in the cwd.
        #  This assumption is made because they expect you to always run RT-STPS
        #  from its install directory.
        #  Fix this by copying the leapsec file to the cwd
        leapsec_source = "#{ENV['RTSTPS_HOME']}/leapsec.dat"
        FileUtils.cp(leapsec_source, '.') if File.exist?(leapsec_source)

        shell_out!("#{conf['rtstps_driver']} #{conf['configs'][platform]} ../#{sourcefile}", clean_environment: true)
        copy_output(output, '*.h5')
        copy_output(output, '*.PDS')
        copy_output(output, 'tp*.dat')
      end
    end
  end
end

RtstpsClamp.run
