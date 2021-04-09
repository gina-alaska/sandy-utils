require 'mixlib/shellout'
require 'shellwords'

module ProcessingFramework
  module ShellOutHelper
    SHELL_OUT_DEFAULTS = { live_stream: STDOUT, timeout: 60 * 60 }

    # runs command, with opts
    # runs command with `env -i` if :clean_environment is passed as option
    def shell_out(command, opts = {})
      if opts.delete(:clean_environment)
        command = "env -i bash -l -c #{command.shellescape}"
      end
      opts = SHELL_OUT_DEFAULTS.merge(opts)
      cmd = ::Mixlib::ShellOut.new(command, opts)
      cmd.run_command

      if (cmd.error?)
        puts("WARNING: the command \"#{command}\" returned an error")
      end

      cmd
    end

    # runs command, with opts, and throws an exception on an error
    def shell_out!(command, opts = {})
      cmd = shell_out(command, opts)
      cmd.error!

      cmd
    end

    def inside(directory)
      create_workdir(directory)
      FileUtils.cd(directory) do
        yield
      end
    rescue RuntimeError => e
      exit_with_error(e.to_s, 10)
    ensure
      cleanup_workdir(directory) unless debug?
    end

    def copy_output(output, save_glob = '*', copy_dirs = false)

      size = 0; 
      start_time = Time.now
      # add trailing slash, if needed
      output += '/' if output[-1] != '/'

      FileUtils.mkdir_p(output) unless (File.exist?(output))
      Dir.glob(save_glob).each do |x|
        if (File.file?(x) || copy_dirs)
          puts("INFO: Copying #{x} to #{output}")
          FileUtils.cp_r(x, output)
	  size += File.size?(x)
        else
          puts("INFO: Not a file, skipping #{x} to #{output}")
        end
      end

      time_diff = Time.now - start_time
      speed = ((size/(1024.0*1024.0))/time_diff).round
      size_in_mb = sprintf("%.2f", size/(1024.0*1024.0))
      puts("INFO: Copy to shared storage took #{(time_diff/60).round} minutes or #{(time_diff).round} seconds")
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
