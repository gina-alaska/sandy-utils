#!/usr/bin/env ruby

ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('..', __dir__), 'Gemfile')
require 'bundler/setup'
require 'clamp'
require_relative '../lib/processing_framework'

class GoogleDriveClamp < ProcessingFramework::CommandLineHelper
  banner 'This tool inserts files into an LDM queue using pqinsert'

  option ['-p', '--prefix'], 'prefex', 'root to push to', default: '/NRT/PROD'
  option ['-d', '--drive_path'], 'drive_path', 'path to drive util', default: '~/gopath/bin/drive'

  parameter 'INPUT', 'Input file or directory'
  parameter '[FILTER]', 'GLOB to filter with, if given a directory. Must be escaped or wrapped in quotes', default: '*'

  def execute
    input_files = if File.directory?(input.to_s)
                    Dir.glob(File.join(input, filter || '*'))
                  else
                    Array(input)
                  end

    input_files.each do |input_file|
      next if File.directory? input_file

      FileUtils.cd('/home/jecable/drive') do
        basename = File.basename(input_file)
        path_clean = File.dirname(input_file)
        path_clean['/gluster/cache'] = ''
        path = prefix.to_s + path_clean
        FileUtils.rm(basename) if File.exist?(basename)
        FileUtils.ln_s(input_file, '.')
        command = "#{drive_path} push -upload-chunk-size 268435456  -fix-clashes -fix-mode trash -no-prompt -destination #{path} #{basename} "
        puts("INFO: running #{command}")
        shell_out!(command) # , clean_environment: true )
        FileUtils.rm(basename)
      end
    end
  end
end

GoogleDriveClamp.run
