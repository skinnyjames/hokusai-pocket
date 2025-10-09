module Hokusai::Pocket::Commands
  @[ACONA::AsCommand("dev", description: "Starts a dev program within a Hokusai::Pocket")]
  class Dev < ACON::Command
    include Barista::Behaviors::Software::OS::Information

    protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
      target = input.option("app") || nil
      directory = input.argument("directory") || nil
      sys = input.option("target") || nil
      config = Hokusai::Pocket::Config.build do |config|
        sys.try do |s|
          config.set_build_system(s)
        end
        target.try do |dir|
          config.set_app_target(dir)
        end

        directory.try do |dir|
          config.set_directory(dir)
        end
      end

      begin
        Hokusai::Pocket::Builder.new(config).build(workers: 1, filter: ["dev"])
      rescue ex
        output.puts("<error>Build failed: #{ex.message}</error>")
      end

      ACON::Command::Status::SUCCESS
    end

    def configure : Nil
      self
        .argument("directory", :optional, "The project to work from")
        .option("target", "t", :optional, "the build target (web | linux | android | web | nintendo | mingw) (defualt: default)")
        .option("app", "a", :optional, "The app to target (default src/app.rb)")
        .option("workers", "w", :optional, "The number of concurrent build workers (default #{memory.cpus.try(&.-(1)) || 1})")
    end
  end
end
