#!/usr/bin/env ruby
# mirs for atmp
# Run like:
# mirs_awips.rb -s atms -t /hub/raid/jcable/sandy/temp/ in out

ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('../..', __FILE__), 'Gemfile')
require 'bundler/setup'
require 'fileutils'
require_relative '../lib/processing_framework'

class MirsAwipsClamp <  ProcessingFramework::CommandLineHelper
  default_config 'mirs_awips'
  banner 'This tool does MIRS l1 to awips for ATMS.'
  option ['-s', '--sensor'], 'sensor', 'The sensor this data is from (atms)', attribute_name: :sensor

  parameter 'INPUT', 'Input directory'
  parameter 'OUTPUT', 'Output directory'

  def execute
    exit_with_error('Unknown sensor..', 19) if conf['processing'][sensor].nil?

    basename = File.basename(input) unless basename

    working_dir = "#{tempdir}/#{basename}"
    inside(working_dir) do
      command = "#{conf['processing'][sensor]['driver']} --backend-configs #{get_config_item(conf['processing'][sensor]['p2g_backend'])} -f #{input}/NPR-MIRS-IMG*.nc"
      result = shell_out!(command)

      # compress
      conf['processing'][sensor]['save'].each do |awips_file|
        gzip!(awips_file)
      end

      conf['processing'][sensor]['save'].each do |glob|
        copy_output(output, glob)
      end
    end
  end


  #finds an item in config/
  def get_config_item(item)
    File.join(File.expand_path('../../config', __FILE__), item)
  end

end

MirsAwipsClamp.run
