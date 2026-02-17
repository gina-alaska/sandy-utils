#!/usr/bin/env ruby
ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('..', __dir__), 'Gemfile')
require 'bundler/setup'
require 'clamp'
require_relative '../lib/processing_framework'
require 'benchmark'
require 'date'
require 'pp'

class AwipsS3PushCamp < ProcessingFramework::CommandLineHelper
  banner 'This pushes data to a s3 bucket for awips in the cloud'

  default_config 'awips_s3_push'

  parameter 'INPUT', 'Input file or directory'

  def execute
    return unless File.directory? input

    platform, time_of_pass = parse_name(input)

    url = time_of_pass.strftime(conf['awips']['url'])

    puts("INFO: Data from #{platform} / #{time_of_pass}")
    puts("INFO: Transfering to #{url}")
    command = "aws s3 sync  --profile #{conf['awips']['aws_profile']} #{input}/ #{url}"
    time = Benchmark.realtime { shell_out!(command) }
    puts("INFO: S3 upload took #{time}s")
  end

  def parse_name(filename)
    name = File.basename(filename).downcase
    puts("INFO: Getting details for: #{name}")
    case name
    when /^npp.\d{5}.\d{4}/ then      ['snpp', parse_date(name, 'npp.%y%j.%H%M')]
    when /^npp.\d{8}.\d{4}/ then      ['snpp', parse_date(name, 'npp.%Y%m%d.%H%M')]
    when /^a1.\d{5}.\d{4}/ then       ['aqua', parse_date(name, 'a1.%y%j.%H%M')]
    when /^aqua.\d{8}.\d{4}/ then     ['aqua', parse_date(name, 'aqua.%Y%m%d.%H%M')]
    when /^t1.\d{5}.\d{4}/ then       ['terra', parse_date(name, 't1.%y%j.%H%M')]
    when /^terra.\d{8}.\d{4}/ then    ['terra', parse_date(name, 'terra.%Y%m%d.%H%M')]
    when /^tp\d{13}.metop-b/ then ['metop-b', parse_date(name, 'tp%Y%j%H%M')]
    when /^tp\d{13}.metop-c/ then ['metop-c', parse_date(name, 'tp%Y%j%H%M')]
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
    when /^aws1.\d{8}.\d{4}/ then     ['aws', parse_date(name, 'aws1.%Y%m%d.%H%M')]
    # TODO:  DMSP
    else ['unknown', Time.now]
    end
  end

  def parse_date(filename, pattern)
    DateTime.strptime(filename, pattern)
  end
end

AwipsS3PushCamp.run
