module Hokusai::Pocket::Commands
  # Downloads dependencies and
  # Compiles a generic dev program for the environment
  @[ACONA::AsCommand("compile", description: "Setup a new Hokusai::Pocket project")]
  class Compile < ACON::Command
    include Barista::Behaviors::Software::OS::Information

    protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
      workers = input.option("workers", Int32?) || memory.cpus.try(&.-(1)) || 1
      target = input.option("target") || nil
      tasks = input.argument("types") || nil
      config = Hokusai::Pocket::Config.build do |config|
        if t = target
          config.set_app_target(t)
        else
          helper = self.helper ACON::Helper::Question
          question = ACON::Question::Choice.new("What system are you building for? (default: default)", {"default", "android", "web", "nintendo", "mingw"})
          sys = helper.ask(input, output, question).as(String)
          
          sys.try do |dir|
            config.set_build_system(sys)
          end
        end
      end

      if t = tasks
        filter = t.split(",").map do |thing|
          "compile-#{thing}"
        end
      else
        filter = ["compile-ast", "compile-mruby", "compile-raylib", "compile-tree-sitter"]
      end

      begin
        Hokusai::Pocket::Builder.new(config).build(workers: workers, filter: filter)
      rescue ex
        output.puts("<error>Build failed: #{ex.message}</error>")
      end

      ACON::Command::Status::SUCCESS
    end

    def configure : Nil
      self
        .argument("types", :optional, "comma delimited things to compile")
        .option("non-interactive", "s", :none, "skip interactive setup")
        .option("target", "t", :optional, "the build target (web | linux | android | web | nintendo | mingw) (defualt: default)")
        .option("workers", "w", :optional, "The number of concurrent build workers (default #{memory.cpus.try(&.-(1)) || 1})")
    end
  end
end
