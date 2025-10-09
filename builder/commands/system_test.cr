module Hokusai::Pocket::Commands
  @[ACONA::AsCommand("system-test", description: "Runs system tests")]
  class SystemTest < ACON::Command
    include Barista::Behaviors::Software::OS::Information

    protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
      helper = self.helper ACON::Helper::Question
      config = Hokusai::Pocket::Config.new
      directory = input.argument("directory") || nil

      directory.try do |dir|
        config.set_directory(dir)
      end

      begin
        Hokusai::Pocket::Builder.new(config).build(workers: 1, filter: ["system-test"])
      rescue ex
        output.puts("<error>Build failed: #{ex.message}</error>")
      end

      ACON::Command::Status::SUCCESS
    end

    def configure : Nil
      self
        .argument("directory", :optional, "the directory to build this project (default ./hokusai-pocket-project)")
        .option("workers", "w", :optional, "The number of concurrent build workers (default #{memory.cpus.try(&.-(1)) || 1})")
    end
  end
end
