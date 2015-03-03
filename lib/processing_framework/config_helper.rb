module ProcessingFramework
  class ConfigLoader
    require 'yaml'
    def initialize(t)
      @conf = load(get_config_path(t))
    end

    def [](k)
      @conf[k]
    end

    def get_name(t)
      File.basename(t, '.rb')
    end

    def get_config_path(t)
      File.dirname(t) + '/../config/' + get_name(t) + '.yml'
    end

    def load(t)
      File.open(t) { |fd| YAML.load(fd) }
    end

    def ConfigLoader.default_path(t)
      File.dirname(t) + '/../config/' + File.basename(t, '.rb') + '.yml'
    end
  end
end
