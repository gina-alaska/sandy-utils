module ProcessingFramework
  class ConfigLoader
    require 'yaml'

    def initialize(filename)
      begin
        @conf = YAML.load_file(get_config_path(filename))
      rescue Errno::ENOENT => e
        @conf = YAML.load_file(get_config_path("#{filename}.yml"))
      end
    end

    def [](k)
      @conf[k]
    end

    def get_name(filename)
      File.basename(filename, '.rb')
    end

    def get_config_path(filename)
      # This method should recieve an absolute path or a filename
      # If we recieve a filename, then assume the default from config should be loaded
      if File.basename(filename) == filename
        filename = File.join(File.expand_path("../../../config", __FILE__), filename)
      end

      filename
    end

    def ConfigLoader.default_path(filename)
      File.dirname(filename) + '/../config/' + File.basename(filename, '.rb') + '.yml'
    end
  end
end
