#!/usr/bin/env ruby

ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('../..', __FILE__), 'Gemfile')
require 'bundler/setup'
require 'clamp'
require_relative '../lib/processing_framework'

class PqinsertClamp <  Clamp::Command
  @description = 'This tool inserts files into an LDM queue using pqinsert'

  option ['-s', '--suffix'], 'suffix', 'Append this string to the name of the file when inserting'
  option ['-f', '--feed'], 'feed', 'The feed to insert into', default: 'EXP'
  option ['-q', '--queue'], 'queue', 'The queue to insert into', default: '$LDMHOME/var/queues/ldm.pq'

  parameter 'INPUT', 'Input file or directory'
  parameter '[FILTER]', 'GLOB to filter with, if given a directory. Must be escaped or wrapped in quotes', default: '*'

  def execute
    input_files = if File.directory?(input.to_s)
                    Dir.glob(File.join(input, filter || '*'))
                  else
                    Array(input)
    end

    input_files.each do |input_file|
      # I don't think pqinsert takes kindly to being given a directory.
      # Probably not reasonable to recurse through directories
      next if File.directory? input_file

      insert_name = [::File.basename(input_file), suffix].compact.join('')

      command = "pqinsert -p #{insert_name} -f #{feed} -q #{queue} -i #{input_file}"
      ProcessingFramework::ShellOutHelper.run_shell(command)
    end
  end
end

PqinsertClamp.run
