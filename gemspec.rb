project("hokusai-pocket") do |config|
  config.option "file", "f" :required, tasks: %w[dev]

  require git: "https://github.com/skinnyjames/theorem.git", spec: "something/spec.rb" 

  task "setup" do |r|
    def build
      command("rm -Rf vendor")
      command("mkdir -p vendor")
    end
  end

  task "clean" do
    def build
      command("make clean", chdir: "vendor/raylib")
      command("make clean PREFIX=build", chdir: "vendor/tree-sitter")
    end
  end
  
  # bulids libraylib.a
  task "raylib" do |raylib|
    dependency "setup"

    def build
      command("rm -rf raylib")
      command("git clone https://github.com/raysan5/raylib.git vendor/raylib")
      command("make clean", chdir: "vendor/raylib/src")
      command("make -j 5 PLATFORM=PLATFORM_DESKTOP", chdir: "vendor/raylib/src")
      # config.cc.objs << "#{path}/vendor/raylib/src/libraylib.a"
      # config.cc.includes << File.join(path, "vendor", "raylib", "src")
    end
  end

  # builds libtree-sitter.a
  task "tree-sitter" do |ts|
    dependency "setup"

    def build
      command("rm -rf vendor/tree-sitter")
      command("git clone https://github.com/tree-sitter/tree-sitter.git vendor/tree-sitter")
      command("mkdir -p vendor/tree-sitter/build")
      command("make -j 5 all install PREFIX=build", chdir: "vendor/tree-sitter", env: env)

      # config.cc.objs << "#{path}/vendor/tree-sitter/build/lib/libtree-sitter.a"
      # config.cc.includes << File.join(path, "vendor", "tree-sitter", "build", "include")
    end

    def build_dir
      "vendor/tree-sitter/build"
    end

    def env
      {
        "CC" => config.cc.gcc,
        "PREFIX" => build_dir
      }
    end 
  end

  # builds libmruby.a
  task "mruby" do |mruby|
    def build
      command("rm -rf vendor/mruby")
      command("git clone https://github.com/mruby/mruby.git vendor/mruby")
      command("rake")
    end
  end


  task "dev" do |args|
    dependency "hokusai" do
      files "vendor/hokusai/libhokusai.a", "vendor/hokusai/hokusai-runner"
    end

    # reads a hokusai ruby entrypoint and runs it
    def build
      command("hokusai-runner #{args[:file]}")
    end
  end

  task "package" do |args|
    dependency "hokusai" do
      files "vendor/hokusai/libhokusai.a"
    end

    dependency "mruby" do
      files "vendor/mruby/build/#{host(args)}/bin/mrbc"
    end

    def build
      # compile file into c bytecode
      command("mrbc #{args[:file]}")
      ruby do
        File.open("")
      end
    end
  end

  # builds libhokusai.a
  # packages 
  task "hokusai" do |hb|
    dependency "raylib" do
      files "vendor/raylib/src/libraylib.a"
    end

    dependency "tree-sitter" do
      files "vendor/tree-sitter/build/lib/libtree-sitter.a"
    end

    dependency "mruby" do

    end

    def sources
      glob(File.join(path, "src", "*.c"))
    end

    def objs
      glob(File.join(path, "src", "*.o"))
    end

    def build
      ruby do
        resolve_requires("mrblib/hokusai.rb")
      end

      ruby do
        command("#{config.cc.gcc} -Igrammar/tree_sitter -Isrc -Ivendor/mruby/include -c #{source.join(" ")}")
          .forward_output(&on_output)
          .execute

        command("#{config.cc.ar} r libhokusai.a #{objs}")
      end

      # # src/hp/backend.c
      # config.cc.objs += %w[
      #   src/ast/log.c
      #   src/ast/hml.c
      #   src/ast/style.c
      #   src/ast/hashmap.c
      #   src/ast/ast.c
      #   grammar/src/parser.c
      #   grammar/src/scanner.c
      #   src/hp/ast/event.c
      #   src/hp/ast/func.c
      #   src/hp/ast/loop.c
      #   src/hp/ast/prop.c
      #   src/hp/ast.c
      #   src/hp/error.c
      #   src/hp/font.c
      #   src/hp/style.c
      #   src/hp/monotonic_timer.c
      # ].map { |p| File.join(path, p) }
    end
  end
end

barista --gcc="clang" --brew="gemspec.rb" dev

