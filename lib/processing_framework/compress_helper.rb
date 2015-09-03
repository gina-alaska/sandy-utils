module ProcessingFramework
  module CompressHelper
    include ShellOutHelper

    def uncompress(file)
      filename = case File.extname(file)
      when '.gz'
        shell_out!("gunzip #{file}", live_stream: false)
        File.basename(file, '.gz')
      when '.bz2'
        shell_out!("bunzip2 #{file}", live_stream: false)
        File.basename(file, '.bz2')
      else
        file
      end

      filename
    end

    def gzip!(file)
      shell_out!("gzip #{file}", live_stream: false)
      "#{file}.gz"
    end

    def bzip2!(file)
      shell_out!("bzip2 #{file}", live_stream: false)
      "#{file}.bz2"
    end
  end
end
