# frozen_string_literal: false

require 'mixlib/shellout'
require 'shellwords'
require 'aws-sdk-s3'

module ProcessingFramework
  module ShellOutHelper
    SHELL_OUT_DEFAULTS = { live_stream: $stdout, timeout: 60 * 60 }.freeze

    # runs command, with opts
    # runs command with `env -i` if :clean_environment is passed as option
    def shell_out(command, opts = {})
      # default to clean_environment
      if opts[:clean_environment] == false
        puts('INFO: shell_out WITHOUT clean environment')
      # do not do clean_environment - not sure if anything needs to do here.
      else
        puts('INFO: shell_out with clean environment')
        command = "env -i bash -l -c #{command.shellescape}"
      end

      opts.delete(:clean_environment)

      opts = SHELL_OUT_DEFAULTS.merge(opts)
      cmd = ::Mixlib::ShellOut.new(command, opts)
      cmd.run_command

      puts("WARNING: the command \"#{command}\" returned an error") if cmd.error?

      cmd
    end

    # runs command, with opts, and throws an exception on an error
    def shell_out!(command, opts = {})
      cmd = shell_out(command, opts)
      cmd.error!

      cmd
    end

    def inside(directory, &block)
      create_workdir(directory)
      FileUtils.cd(directory, &block)
    rescue RuntimeError => e
      exit_with_error(e.to_s, 10)
    ensure
      cleanup_workdir(directory) unless debug?
    end

    def copy_output(output, save_glob = '*', copy_dirs = false)
      # Start with size 0
      size = 0
      start_time = Time.now

      # check to see if output dir is a s3 url..
      s3 = false
      s3_prefix = +''
      if output =~ %r{^s3://.*}
        # maybe should support this format as well
        # || output =~ /^arn:aws:s3\.*/
        s3, s3_prefix = %r{^s3://([a-zA-Z0-9\-._]+)([/a-zA-Z0-9\-.\\_]*)}.match(output)[1, 2]
        if !s3_prefix || s3_prefix == '' || s3_prefix == '/' # catch odd values, make sure they are empty
          s3_prefix = +''
        elsif s3_prefix[-1] != '/'
          s3_prefix += '/'
        end
        s3_prefix.delete_prefix!('/')
      end

      # add trailing slash, if needed
      output += '/' if output[-1] != '/'

      FileUtils.mkdir_p(output) unless !s3 && File.exist?(output)
      Dir.glob(save_glob).each do |x|
        if (File.file?(x) || copy_dirs)
          size += File.size?(x)
          if s3
            begin
              s3_object = Aws::S3::Object.new(
                s3, s3_prefix + File.basename(x)
              )
              s3_object.upload_file(x)
            rescue Aws::Errors::ServiceError => e
              puts "ERROR: Couldn't upload file #{x} to #{s3_object.key}. Here's why: #{e.message}"
              exit_with_error(
                e.to_s, 10
              )
            end
          elsif File.size?(x) > 1024 * 1024 * 4
            # if bigger than 4m, shell out
            puts("INFO: Copying via system #{x} to #{output}")
            system('/bin/cp', x, output)
          else
            puts("INFO: Copying #{x} to #{output}")
            FileUtils.cp_r(x, output)
          end
        else
          puts("INFO: Not a file, skipping #{x} to #{output}")
        end
      end

      # calculate copy speed.
      time_diff = Time.now - start_time
      speed = ((size / (1024.0 * 1024.0)) / time_diff).round
      size_in_mb = format('%.2f', size / (1024.0 * 1024.0))
      puts("INFO: Copy to shared storage took #{(time_diff / 60).round} minutes or #{time_diff.round} seconds")
      puts("INFO: Size of data copied is #{size_in_mb} Mbytes")
      puts("INFO: Rate ~#{speed} Mbytes/sec")
    end

    private

    def create_workdir(directory)
      cleanup_workdir(directory)
      FileUtils.mkdir_p(directory)
    end

    def cleanup_workdir(directory)
      FileUtils.remove_entry_secure(directory) if File.exist?(directory)
    end

    def debug?
      !!ENV['DEBUG']
    end
  end
end
