#!/usr/bin/env ruby
# SDR processing tool..
# Run like:
# nasa_anc_fetch.rb

ENV['BUNDLE_GEMFILE'] = File.join(File.expand_path('../..', __FILE__), 'Gemfile')
require 'bundler/setup'
require 'fileutils'
require_relative '../lib/processing_framework'

class AncFetchClamp <  ProcessingFramework::CommandLineHelper
  default_config 'nasa_sdr'
  banner 'This tool does SDR processing for SNPP using the NASA toolset.'

  option ['-m', '--mode'], 'mode', "The SDR to process, valid options are viirs.", default: 'viirs'

  def execute
    exit_with_error("Unknown/unconfigured mode: #{mode}", 19) unless conf['configs'][mode]


    working_dir = "#{tempdir}/#{basename}"
    inside(working_dir) do
      processing_cfg = conf['configs'][mode]
      fetch_anc(processing_cfg)
    end
  end


 def fetch_anc(cfg)
	cfg["anc"].each do |name, set|
		update_anc_set(set)
	end
 end

#Fetchs new anc from upstream
  def update_anc_set(set)
	command = "wget -q -c -P #{set["location"]} #{set["url"]}"
	shell_out!(command)
  end

end

AncFetchClamp.run
