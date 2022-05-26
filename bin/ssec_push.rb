#!/usr/bin/env ruby


ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('..', __dir__), 'Gemfile')
require 'bundler/setup'
require 'clamp'
require_relative '../lib/processing_framework'

require 'benchmark'

class SsecPushClamp < ProcessingFramework::CommandLineHelper
  banner 'This ftps data to SSEC'

  option ['-s', '--source'], 'source', 'the source the data is from', default: 'uafgina'

  default_config 'ssec_push'

  parameter 'INPUT', 'Input file or directory'

  def execute
    if !conf[source]
      puts("INFO: Transfer from #{source} not configured.")
    else
      cfg = conf[source]
      input_files = []
      cfg['glob'].each do |pattern|
        input_files += Dir.glob(input + '/' + pattern)
      end

      input_files.each do |input_file|
        basename = File.basename(input_file)

        next if File.directory? input_file

        command = "ncftpput  #{cfg['ftp']['options']} -T INPROGRESS_ -C #{cfg['ftp']['host']} #{input_file} #{cfg['ftp']['dir']}/#{basename}"
        time = Benchmark.realtime { shell_out!(command) }
        puts("INFO: #{basename},size #{((File.size(input_file) / (1024 * 1024.0)) * 10.0).to_i / 10.0}Mb, took #{time}s")
      end
    end
    true
  end
end

SsecPushClamp.run
