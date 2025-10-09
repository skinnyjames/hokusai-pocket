module Hokusai::Pocket
  module Mixins::BuildAst
    def files
      %w[
        hoku-log.c 
        hoku-hml.c 
        hoku-ast.c 
        hoku-style.c 
        hoku-hashmap.c 
        ts-parser.c 
        ts-scanner.c
        hp-ast.c
        hp-style.c
        hp-error.c
        hp-font.c
        hp-style.c
        hp-backend.c
      ]
    end

    def build : Nil
      mkdir(File.join(include_dir, "ast"), parents: true)
      mkdir(File.join(include_dir, "hp"), parents: true)
      mkdir(File.join(ast_dir, "tree_sitter"), parents: true)
      mkdir(File.join(ast_dir, "ast"), parents: true)
      mkdir(build_dir, parents: true)

      block do
        File.write(File.join(ast_dir, "hokusai-pocket.rb"), FileStorage.hokusai_code)
      end

      command("#{mrbc} -o#{include_dir}/hokusai-pocket.h -Bhokusai_pocket ./hokusai-pocket.rb", chdir: ast_dir)

      block do
        ["ast", "hml", "log", "style", "hashmap"].each do |prefix|
          File.write(File.join(include_dir, "ast", "#{prefix}.h"), FileStorage.get("ast/#{prefix}.h").gets_to_end)
          File.write(File.join(ast_dir, "hoku-#{prefix}.c"), FileStorage.get("ast/#{prefix}.c").gets_to_end)
        end

        ["parser", "scanner"].each do |prefix|
          File.write(File.join(ast_dir, "tree_sitter/#{prefix}.h"), FileStorage.get("tree_sitter/#{prefix}.h").gets_to_end)
          File.write(File.join(ast_dir, "ts-#{prefix}.c"), FileStorage.get("#{prefix}.c").gets_to_end)
        end

        ["event", "func", "loop", "prop"].each do |prefix|
          File.write(File.join(ast_dir, "ast", "#{prefix}.c"), FileStorage.get("hp/ast/#{prefix}.c").gets_to_end)
        end

        ["ast", "style", "font", "error", "backend"].each do |prefix|
          File.write(File.join(include_dir, "hp", "#{prefix}.h"), FileStorage.get("hp/#{prefix}.h").gets_to_end)
          File.write(File.join(ast_dir, "hp-#{prefix}.c"), FileStorage.get("hp/#{prefix}.c").gets_to_end)
        end
      end

      command("#{gcc} -O3 -Wall -I#{include_dir} -I#{include_dir}/ast -I. -I../include -c #{files.map {|f| "../#{f}" }.join(" ")}", chdir: build_dir)
      # command("cp ../lib/libtree-sitter.a libtree-sitter.a && #{ar} -x libtree-sitter.a", chdir: build_dir)
      command("#{ar} rcs libpocket.a *.o", chdir: build_dir)
      copy("libpocket.a", File.join(lib_dir, "libpocket.a"), chdir: build_dir)
      command("rm -rf #{build_dir}")
    end

    def build_dir
      File.join(ast_dir, "build")
    end

    def ast_dir
      File.join(vendor_dir, "ast")
    end
  end
end