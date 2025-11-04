class File
   module Private
    def self.to_path_str(path, is_optional=false)
      if path.kind_of?(String)
        path
      else
        if path.respond_to?(:to_path)
          path = path.to_path
        elsif path.respond_to?(:to_str)
          path = path.to_str
        elsif is_optional && path.nil?
          nil
        else
          raise TypeError.new("String expected")
        end
      end
    end
  end
end

class Pathname
  ROOT = '/'
  DOT = '.'
  DOT_DOT = '..'
  
  def initialize(path_str)
    path_str = File::Private.to_path_str(path_str)
    @path = path_str.dup
  end
  
  def self.join(*parts)
    parts = parts.flatten
    
    rooted = false
    if parts[0] == ROOT
      rooted = true
    end
    
    parts = parts.select{ |p|
      !p.nil? && p != File::SEPARATOR
    }.map { |p| 
      p.to_s
    }
    
    str = parts.join(File::SEPARATOR)
    if rooted
      str = "#{ROOT}#{str}"
    end
    
    str = str.each_char.inject('') do |acc, cur|
      acc.concat(cur) unless acc[acc.length - 1] == cur && cur == File::SEPARATOR
      acc
    end
    
    str
  end
  
  def +(other)
    Pathname.new(self.to_s + File::SEPARATOR + other.to_s)
  end
  
  # Non-standard
  def <<(other)
    @path.concat(File::SEPARATOR).concat(other.to_s)
    self
  end
  
  def absolute?
    @path.start_with?(ROOT)
  end
  
  def dup
    Pathname.new(@path.dup)
  end
  
  # Non-standard
  def cleanpath!
    parts = each_filename.to_a
    
    if absolute?
      parts.unshift ROOT
    end

    result = []
    parts.each do |part|
      case part
      when DOT
        next
      when DOT_DOT
        case result.last
        when ROOT
          # No parent directory of the root
          next
        when DOT_DOT
          # If the last part was deemed a useful parent ref,
          # then we need this one too.
          result.push(DOT_DOT)
        when nil
          # This is the first part of the path, it must be useful.
          result.push(DOT_DOT)
        else
          # There is a path segment we can just pop to reduce the ..
          result.pop
        end
      else
        result.push(part)
      end
    end

    replace(result.empty? ? DOT : self.class.join(*result))
    
    self
  end

  # Cleans the path by removing consecutive slashes, and useless dots.
  def cleanpath
    dup.cleanpath!
  end
  
  def hash
    @path.hash
  end
  
  def parent
    if root?
      self
    else
      names = each_filename.to_a[0...-1]
      if self.absolute?
        names.unshift(ROOT)
      end
      Pathname.new(Pathname.join(names))
    end
  end
  
  # Non-standard
  def replace(new_path)
    @path = new_path.to_s.dup
    self
  end
  
  def relative?
    !@path.start_with?(ROOT)
  end
  
  def root?
    return false if @path.length == 0
    @path.each_char do |c|
      return false unless c == ROOT
    end
    true
  end
  
  def sub(pattern, replacement)
    Pathname.new(self.to_s.sub(pattern, replacement))
  end
  
  def each_filename
    return self.enum_for(:each_filename) unless block_given?
    
    @path.split(File::SEPARATOR).
      select { |p| p && !p.empty? }.
      each { |f| yield f }
  end
  
  def to_s
    @path.dup
  end
  alias to_str to_s
end

class Resolver
  def self.write_to_file(path, filename)
    code = new(path).code
    File.open(filename, "w") do |io|
      io << code
    end
  end

  def initialize(file_path, document = File.read(file_path))
    @file_path = file_path
    @document = document
  end

  def code
    resolve_imports!

    @document
  end

  def resolve_imports!
    file_path_dir = File.dirname(@file_path)

    @document = @document.gsub(/(?:require_relative\s+["'](.*)["'])/) do |path|
      base_path = Pathname.new(@file_path)
      path = Pathname.new("#{path.gsub(/require_relative\s+["']/, "").chop}.rb")
      resolved_path = Pathname.join(File.dirname(base_path.to_s), path).to_s

      Resolver.new(resolved_path).code
    end
  end
end

def top
  binding
end

spec("hokusai-pocket") do |config|
  task "setup" do
    def build
      mkdir("vendor")
      command("touch vendor/.keep")
      command("git clone https://github.com/raysan5/raylib.git vendor/raylib && cd vendor/raylib && git checkout 5.5")
      command("git clone https://github.com/tree-sitter/tree-sitter.git vendor/tree-sitter")
      command("git clone https://github.com/mruby/mruby.git vendor/mruby && cd vendor/mruby && git checkout stable")
    end
  end

  task "clean" do
    def build
      command("rm -Rf vendor")
    end
  end

  task "raylib" do |args|
    dependency "setup" do
      files "vendor/.keep"
    end

    def platform(args)
      case args[:platform]
      when "sdl"
        "PLATFORM_SDL"
      else
        "PLATFORM_DESKTOP"
      end
    end

    def build
      command("make clean", chdir: "vendor/raylib/src")
      command("make -j 5 PLATFORM=#{platform(args)}", chdir: "vendor/raylib/src")
    end
  end

  task "tree-sitter" do |args|
    dependency "setup" do
      files "vendor/.keep"
    end

    def build
      command("mkdir -p vendor/tree-sitter/build")
      command("make -j 5 all install PREFIX=build", chdir: "vendor/tree-sitter")
    end
  end

  task "mruby" do
    dependency "setup" do
      files "vendor/.keep"
    end

    def build
      ruby do
        File.open("vendor/mruby/cli_build_config.rb", "w") do |io|
          str = <<-RUBY
            MRuby::Build.new do |conf|
              if ENV['VisualStudioVersion'] || ENV['VSINSTALLDIR']
                toolchain :visualcpp
              else
                toolchain :clang
              end

              conf.gembox "full-core"
              conf.gem github: "skinnyjames/mruby-bin-barista", branch: "main"
            end
          RUBY

          io << str
        end
      end

      command("MRUBY_CONFIG=cli_build_config.rb rake", chdir: "vendor/mruby")
    end
  end

  task "hokusai" do |args|
    dependency "raylib" do
      files "vendor/raylib/src/libraylib.a"
    end
    
    dependency "tree-sitter" do
      files "vendor/tree-sitter/build/lib/libtree-sitter.a"
    end
    
    dependency "mruby" do
      files "vendor/mruby/build/host/lib/libmruby.a"
    end

    def sources
      glob(File.join(path, "src", "*.c"))
    end

    def objs
      glob(File.join(path, "vendor", "hokusai-pocket", "*.o"))
    end

    def glob(path)
      Dir.glob(path)
    end

    def mrbc
      "vendor/mruby/build/host/bin/mrbc"
    end

    def build
      ruby do
        Resolver.write_to_file("ruby/hokusai.rb", "mrblib/hokusai.rb")
      end

      mkdir("vendor/hokusai-pocket")
      command("#{mrbc} -ovendor/hokusai-pocket/pocket.h -Bpocket mrblib/hokusai.rb")
      command("#{config.cc.gcc} -O3 -Wall -I../../vendor/mruby/include -I../../grammar/tree_sitter -I../../src -I. -c #{sources.map { |s| "../../#{s}" }.join(" ")}", chdir: "vendor/hokusai-pocket")
      ruby do
        command("#{config.cc.ar} r libhokusai.a #{objs.map{ |s| "../../#{s}" }.join(" ")}", chdir: "vendor/hokusai-pocket")
          .forward_output(&on_output)
          .execute
      end
    end
  end

  module Helpers
    def mrbc
      "vendor/mruby/build/host/bin/mrbc"
    end

    def includes
      %w[vendor/mruby/include vendor/cli vendor/hokusai-pocket src].map do |file|
        "-I#{file}"
      end
    end

    def frameworks(args)
      case detected_os
      when "MacOS"
        "-framework CoreVideo -framework IOKit -framework Cocoa -framework GLUT -framework OpenGL"
      when "Windows"
        "-lgdi32 -lwinmm"
      when "Linux"
        "-lGL -lm -lpthread -ldl -lrt -lX11"
      else
        ""
      end
    end

    def links
      %w[
          grammar/src/parser.c
          grammar/src/scanner.c
          vendor/hokusai-pocket/libhokusai.a
          vendor/mruby/build/host/lib/libmruby.a 
          vendor/raylib/src/libraylib.a
          vendor/tree-sitter/build/lib/libtree-sitter.a
        ]
    end
  end

  task "cli" do |args|
    include Helpers
    dependency "hokusai" do
      files "vendor/hokusai-pocket/libhokusai.a", "mrblib/hokusai.rb"
    end

    def build
      mkdir("vendor/cli")
      mkdir("bin")
      command("#{mrbc} -ovendor/cli/pocket-cli.h -Bpocket_cli Brewfile")

      ruby do
        File.open("vendor/cli/hokusai-pocket.c", "w") do |io|
          str = <<~C
          #ifndef POCKET_ENTRYPOINT
          #define POCKET_ENTRYPOINT
          
          #include <mruby.h>
          #include <mruby/array.h>
          #include <mruby/irep.h>

          #include <mruby_hokusai_pocket.h>
          #include <pocket.h>
          #include <pocket-cli.h>
          #define OPTPARSE_IMPLEMENTATION
          #define OPTPARSE_API static
          #include <optparse.h>

          int main(int argc, char* argv[])
          {
            mrb_state* mrb = mrb_open();
            mrbc_context *cxt = mrbc_context_new(mrb);
            mrb_mruby_hokusai_pocket_gem_init(mrb);
            mrb_load_irep_cxt(mrb, pocket, cxt);

            struct optparse options;
            optparse_init(&options, argv);
            char *arg;
            mrb_value ary = mrb_ary_new(mrb);
            while ((arg = optparse_arg(&options)))
            {
              mrb_ary_push(mrb, ary, mrb_str_new_cstr(mrb, arg));
            }

            if (mrb->exc)
            {
              mrb_print_error(mrb);
              return 1;
            }
            int ai = mrb_gc_arena_save(mrb);
            mrb_value gemspec = mrb_load_irep_cxt(mrb, pocket_cli, cxt);
            mrb_gc_arena_restore(mrb, ai);

            if (mrb->exc) {
              mrb_print_error(mrb);
              return 1;
            }

            mrb_funcall(mrb, gemspec, "execute", 1, mrb_ary_join(mrb, ary, mrb_str_new_cstr(mrb, " ")));
            if (mrb->exc) {
              mrb_print_error(mrb);
              return 1;
            }

            mrb_close(mrb);
            
          }
          #endif
          C

          io << str
        end
      end

      command("#{config.cc.gcc} -O3 -Wall #{includes.join(" ")} -o bin/hokusai-pocket vendor/cli/hokusai-pocket.c -L. #{links.join(" ")} #{frameworks(args)}")
    end
  end

  task "quick" do |args|
    dependency "hokusai"
    dependency "cli"

    def build
      command("../bin/hokusai-pocket run:target=counter.rb", chdir: "examples")
    end
  end

  task "run" do |args|
    def build
      out = args[:target] || "app.rb"
      code = Resolver.new(out).code

      eval code, top
    end
  end


  task "build" do |args|
    include Helpers
    dependency "hokusai" do
      files "vendor/hokusai-pocket/libhokusai.a"
    end

    def build
      out = args[:target] || "app.rb"
      puts "ok"
      code = ruby_file(out)
      puts "ok"
      fname = File.basename(out).gsub(/\.rb$/, "")
      dir = Pathname.new(out).parent.to_s

      ruby do
        File.open("vendor/cli/papp.rb", "w") do |io|
          io << code
        end
      end

      command("vendor/mruby/build/host/bin/mrbc -ovendor/cli/papp.h -Bpocket_app vendor/cli/papp.rb")
      
      ruby do
        File.open("vendor/cli/#{fname}.c", "w") do |io|
          str = <<~C
          #ifndef POCKET_ENTRYPOINT
          #define POCKET_ENTRYPOINT
          
          #include <mruby.h>
          #include <mruby/array.h>
          #include <mruby/irep.h>

          #include <mruby_hokusai_pocket.h>
          #include <pocket.h>
          #include <papp.h>

          int main(int argc, char* argv[])
          {
            mrb_state* mrb = mrb_open();
            mrb_mruby_hokusai_pocket_gem_init(mrb);
            mrb_load_irep(mrb, pocket);

            int ai = mrb_gc_arena_save(mrb);
            mrb_value gemspec = mrb_load_irep(mrb, pocket_app);
            mrb_gc_arena_restore(mrb, ai);

            if (mrb->exc) {
              mrb_print_error(mrb);
              return 1;
            } 
            mrb_mruby_hokusai_pocket_gem_final(mrb);
            mrb_close(mrb);
          }
          #endif
          C

          io << str
        end
      end

      command("#{config.cc.gcc} -O3 -Wall #{includes.join(" ")} -o bin/#{fname} vendor/cli/#{fname}.c -L. #{links.join(" ")} #{frameworks(args)}")
    end
  end
end