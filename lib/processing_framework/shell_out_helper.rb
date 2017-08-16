require 'mixlib/shellout'

module ProcessingFramework
  module ShellOutHelper
    SHELL_OUT_DEFAULTS = { live_stream: STDOUT, timeout: 60 * 60 }

    # runs command, with opts
    # runs command with `env -i` if :clean_env is passed as option
    def shell_out(command, opts = {})
      if opts[:clean_env].delete do
        command = "env -i "+ command
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
      # add trailing slash, if needed
      output += '/' if output[-1] != '/'

      FileUtils.mkdir_p(output) unless (File.exist?(output))
      Dir.glob(save_glob).each do |x|
        if (File.file?(x) || copy_dirs)
          puts("INFO: Copying #{x} to #{output}")
          FileUtils.cp_r(x, output)
        else
          puts("INFO: Not a file, skipping #{x} to #{output}")
        end
      end
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
