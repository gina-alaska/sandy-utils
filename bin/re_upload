#!/usr/bin/env ruby
# frozen_string_literal: true

# alternitive upload to re_upload

require 'net/http'
require 'openssl'
require 'optparse'
require 'ostruct'

# command line options
class Options
  def self.parse(args)
    options = OpenStruct.new

    # Set default values
    options.key = nil

    opt_parser = OptionParser.new do |opts|
      opts.banner = "Usage: #{__FILE__} [options] [filename] [name/bucket] [date] [time]] "

      opts.separator ''
      opts.separator 'Specific options:'

      opts.on('-k [KEY]', '--key [KEY]', 'Specify a key') do |key|
        options.key = key
      end

      opts.separator ''
      opts.separator 'Common options:'

      # help
      opts.on_tail('-h', '--help', 'Show this message') do
        puts opts
        exit
      end
    end

    opt_parser.parse!(args)
    options
  end
end

options = Options.parse(ARGV)

puts "Key:  #{options.key}" if options.key

# check key
unless options.key
  puts 'Error: --key/-k is missing.'
  exit(-1)
end

if ARGV.length != 4
  puts options.help
  exit(-1)
end

file = ARGV[0]
file_type = ARGV[1]
file_date = ARGV[2]
file_time = ARGV[3]

puts "File:  #{file}"
puts "Type:\t#{file_type}"
puts "Date:\t#{file_date}"
puts "Time:\t#{file_time}"

# check existance of file
unless File.exist?(file) && File.size(file).positive?
  puts("ERROR: Does not exist or is zero lenght: '#{file}'")
  exit(-1)
end


uri = URI('https://re-ngfs.ssec.wisc.edu/upload/')
req = Net::HTTP::Post.new(uri)

req.set_form(
  [
    [
      'file',
      File.open(file)
    ],
    [
      'name',
      file_type
    ],
    [
      'date',
      file_date
    ],
    [
      'time',
      file_time
    ],
    [
      'key',
      options.key
    ]
  ],
  'multipart/form-data'
)

req_options = {
  use_ssl: uri.scheme == 'https',
  verify_mode: OpenSSL::SSL::VERIFY_NONE
}

start_time = Time.now
begin
  Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
    result = http.request(req)
    puts("BODY: #{result.body}") if result.body && !result.body.empty?
    puts("MSG: #{result.msg}")
    puts("CODE: #{result.code}")
    puts("NAME: #{result.class.name}")
    puts("DUR: #{Time.now - start_time} s")

    if result.is_a?(Net::HTTPSuccess)
      puts('STATUS: OK')
      exit(0)
    else
      puts 'STATUS: ERROR'
      exit(1)
    end
  end
rescue StandardError => e
  puts "\nAn unexpected error occurred: #{e.message}"
  exit(1)
end
