module ProcessingFramework
  require 'clamp'
  require 'fileutils'
  require_relative 'shell_out_helper'
  require_relative 'config_helper'

  class CommandLineHelper < Clamp::Command
    include ProcessingFramework::ShellOutHelper

    option ['-c', '--config'], 'config', "Override default config file." do |c|
      default_config File.realpath(c)
    end
    option ['-b', '--basename'], 'basename', 'The basename of the data to be processed. For example npp.14300.1843 .  Appended to --outputdir if included.'
    option ['-t', '--tempdir'], 'tempdir', 'The temp directory, used for working space. A sub directory will made inside this named after the basename.',  environment_variable: 'PROCESSING_TEMPDIR', required: true
    # option ['-i', '--input'], 'input', 'The input file. ', required: true
    # option ['-o', '--outdir'], 'outdir', 'The output directory. If --basename is included, it is appended to this.', required: true


    def execute
      fail 'CommandLineHelper should not be instatiated directly.'
    end

    def conf
      @conf ||= ProcessingFramework::ConfigLoader.new(@@config)
    end

    def self.default_config filename=nil
      @@config ||= "#{filename}.yml" unless filename.nil?
      @@config
    end

    def exit_with_error(message, code)
      puts "Error: #{message}"
      exit code
    end

    def description message
      @description = message
    end

  end
end
