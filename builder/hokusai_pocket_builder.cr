require "barista"
require "file_utils"
require "./config"
require "./file_system"
require "./mixins/build_ast"

module Hokusai::Pocket
  module Task
    getter :config

    def ndk_version
      "29.0.13113456"
    end

    def gcc
      case config.system
      when .web
        "emcc"
      else
        "gcc"
      end
    end

    def ar
      config.system.web ? "emar" : "ar"
    end

    def vendor_dir
      File.join(config.directory, "vendor")
    end

    def src_dir
      File.join(config.directory, "src")
    end

    def mrbc
      if config.system.web
        File.join(config.directory, "target", "default", "bin", "mrbc")
      else
        File.join(bin_dir, "mrbc")
      end
    end

    def dist_dir
      File.join(config.directory, "target", config.system.to_s)
    end

    def include_dir
      File.join(dist_dir, "include")
    end

    def lib_dir
      File.join(dist_dir, "lib")
    end

    def bin_dir
      File.join(dist_dir, "bin")
    end

    def initialize(@config : Hokusai::Pocket::Config, **args)
      super()
    end

    def fetch(target, location : String, **opts)
      begin
        fetcher = Barista::Behaviors::Software::Fetchers::Net.new(location, **opts)
        fetcher.execute(File.join(config.directory, "vendor", "downloads"), File.join("..", target))
      rescue ex : Barista::Behaviors::Software::Fetchers::RetryExceeded
        on_error.call("Failed to fetch: #{ex}")
        raise ex
      ensure
        FileUtils.rm_rf(File.join(config.directory, "*.tar.gz"))
      end
    end
  end

  class Builder < Barista::Project
    include_behavior Software

    getter :config

    def initialize(@config : Hokusai::Pocket::Config); end
    
    def build(workers : Int32, filter : Array(String)? = nil, **args)
      FileUtils.mkdir_p(config.directory)
      FileUtils.mkdir_p(File.join(config.directory, "src"))
      FileUtils.mkdir_p(File.join(config.directory, "vendor", "downloads"))
      FileUtils.mkdir_p(File.join(config.directory, "target", config.system.to_s, "include"))
      FileUtils.mkdir_p(File.join(config.directory, "target", config.system.to_s, "lib"))
      FileUtils.mkdir_p(File.join(config.directory, "target", config.system.to_s, "bin"))

      colors = Barista::ColorIterator.new

      Log.setup_from_env

      tasks.each do |task_klass|
        logger = Barista::RichLogger.new(colors.next, task_klass.name)

        task = task_klass.new(config, **args)

        task.on_output do |str|
          logger.info { str }
        end
  
        task.on_error do |str|
          logger.error { str }
        end
      end

      orchestration = Barista::Orchestrator(Barista::Task).new(registry, workers: workers, filter: filter)
      
      orchestration.on_task_start do |task|
        Barista::Log.debug(task) { "Starting Build" }
      end
      
      orchestration.on_task_failed do |task, ex|
        Barista::Log.error(task) { "build failed: #{ex}" }
      end

      orchestration.on_task_succeed do |task|
        Barista::Log.debug(task) { "build succeeded" }
      end

      orchestration.on_unblocked do |info|
        str = <<-EOH
        Unblocked #{info.unblocked.join(", ")}
        Building #{info.building.join(", ")}
        Active Sequences #{info.active_sequences.map {|k,v| "{ #{k}, #{v} }"}.join(", ")}
        EOH
        Barista::Log.debug(name) { str }
      end

      orchestration.execute
    end
  end
end

require "./tasks/*"
require "./commands/*"

console = ACON::Application.new("hokusai-pocket")
console.add(Hokusai::Pocket::Commands::SystemTest.new)
console.add(Hokusai::Pocket::Commands::Setup.new)
console.add(Hokusai::Pocket::Commands::Dev.new)
console.add(Hokusai::Pocket::Commands::Compile.new)


console.run