module Hokusai::Pocket::Commands
  # Downloads dependencies and
  # Compiles a generic dev program for the environment
  @[ACONA::AsCommand("new", description: "Setup a new Hokusai::Pocket project")]
  class Setup < ACON::Command
    include Barista::Behaviors::Software::OS::Information

    protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
      non_interactive = input.option("non-interactive", Bool)
      workers = input.option("workers", Int32?) || memory.cpus.try(&.-(1)) || 1
      config = Hokusai::Pocket::Config.new

      unless non_interactive
        helper = self.helper ACON::Helper::Question

        question = ACON::Question(String?).new("What is the name of your project? (default: hokusai-pocket-project) ", nil)
        helper = self.helper ACON::Helper::Question
        if name = helper.ask(input, output, question).as(String?)
          config.set_directory(File.join(Dir.current, name))
        end

        config.set_build_system("default")

        question = ACON::Question::Choice.new("Do you want to add a gem?", {"yes", "no"})
        add_gems = helper.ask(input, output, question).as(String)

        while add_gems == "yes"
          question = ACON::Question(String).new("What is the gem source? (eg: github) ", "github")
          source = helper.ask(input, output, question).as(String)

          question = ACON::Question(String?).new("What is the gem name? (eg: takahashim/mruby-forwardable) ", nil)
          if location = helper.ask(input, output, question).as(String?)
            config.add_gem(source, location)
          else
            output.puts("No gem name specified, skipping\n")
          end
          
          question = ACON::Question::Choice.new("Do you want to add another gem?", {"yes", "no"})
          add_gems = helper.ask(input, output, question).as(String)
        end

        config.write_config_file
      else
        directory = input.option("directory", String?) || nil
        gems = input.option("gems", String?) || nil

        directory.try do |dir|
          config.set_directory(File.join(Dir.current, dir))
        end

        config.set_build_system("default")

        gems.try do |gem_list|
          couples = gem_list.split(",")

          couples.each do |couple|
            source, loc = couple.split("::")
            config.add_gem(source, loc)
          end
        end
      end

      begin
        Hokusai::Pocket::Builder.new(config).build(workers: workers, filter: ["ast"])
      rescue ex
        output.puts("<error>Build failed: #{ex.message}</error>")
      end

      ACON::Command::Status::SUCCESS
    end

    def configure : Nil
      self
        .option("non-interactive", "s", :none, "skip interactive setup")
        .option("gems", "g", :optional, "a list of gems delimited by commas <ex: github::takahashim/mruby-forwardable>")
        .option("workers", "w", :optional, "The number of concurrent build workers (default #{memory.cpus.try(&.-(1)) || 1})")
    end
  end
end
