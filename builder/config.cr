module Hokusai::Pocket
  enum System
    Web
    NintendoSwitch
    Linux
    Mingw
    Android
    Default
  end
  
  @[Crinja::Attributes]
  record SystemWrapper, value : System do
    include Crinja::Object::Auto

    def web
      value.web?
    end

    def nintendo_switch
      value.nintendo_switch?
    end

    def linux
      value.linux?
    end

    def mingw
      value.mingw?
    end

    def android
      value.android?
    end

    def default
      value.default?
    end

    def to_s
      case value
      when .web?
        "web"
      when .nintendo_switch?
        "nintendo"
      when .mingw?
        "mingw"
      when .android?
        "android"
      when .linux?
        "linux"
      else
        "default"
      end
    end
  end

  @[Crinja::Attributes]
  record GemDefinition, from : String, path : String? do
    include Crinja::Object::Auto

    def to_s
      if p = path
        "#{from}::#{p}"
      else
        from
      end
    end
  end

  class Config
    getter :directory, :gems, :app_target, :build_target

    @build_target : String?

    def self.locate_config_file
      pos = Dir.current
      while current = Dir.current
        if File.exists?(".pocket")
          file =  File.read(".pocket")
          Dir.cd(pos)
          return {current, file}
        end

        if File.exists?("..")
          Dir.cd("..")
        else
          Dir.cd(pos)
          return nil
        end
      end
    end

    def self.build
      config = new

      if tuple = locate_config_file
        directory, content = tuple
        config.set_directory(directory)
        config.set_from_file(content)
      end

      yield config

      config
    end

    def write_config_file
      FileUtils.mkdir_p(File.join(directory))
      File.open(File.join(directory, ".pocket"), "w") do |io|
        io.puts "system=#{system.to_s}"
        unless gems.empty?
          io.puts gems.map(&.to_s).join(",")
        end
      end
    end

    def initialize
      @directory = Path[Dir.current].join("hokusai-pocket-project").to_s
      @system = System::Default
      @gems = [] of GemDefinition
      @app_target = File.join(@directory, "src", "app.rb")
      @build_target = nil
    end

    def set_from_file(file : String)
      file.split(/\n|\r\n/).each do |key_values|
        next if key_values.blank?
        key, value = key_values.split("=")
        next if value.nil? || key.nil?
        case key
        when "gems"
          value.split(",").each do |source|
            if source =~ /::/
              from, path = source.split("::")
              add_gem(from, path)
            else
              add_gem(source)
            end
          end
        when "system"
          set_build_system(value)
        end
      end
    end

    def set_directory(dir : String)
      puts "setting directory #{dir}"
      @directory = Path[dir].expand.to_s
      @app_target = File.join(@directory, "src", "app.rb")

      self
    end

    def set_build_target(target : String)
      @build_target = target

      self
    end

    def set_app_target(path : String)
      @app_target = Path[path].expand.to_s

      self
    end

    def app_name
      File.basename(@app_target)
    end

    def add_gem(source, path)
      gems << GemDefinition.new(from: source, path: path)
    end

    def add_gem(source)
      gems << GemDefinition.new(from: source, path: nil)
    end

    def system
      SystemWrapper.new(@system)
    end

    def set_build_system(type : String)
      puts "set build system!: #{type}"
      case type
      when "default"
        @system = System::Default
      when "web"
        @system = System::Web
      when "linux"
        @system = System::Linux
        @build_target = "x86_64-linux-gnu"
      when "android"
        @system = System::Android
        @build_target = "aarch64-linux-android"
      when "mingw"
        @system = System::Mingw
      when "nintendo"
        @system = System::NintendoSwitch
      else
        puts "System #{type} not found, using default" unless @system == "default"
        @system = System::Default
      end

      self
    end
  end
end
