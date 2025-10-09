module Hokusai::Pocket
  class Resolver
    getter :file_path

    def initialize(@file_path : String, @document : String = File.read(file_path)); end

    def code
      resolve_imports!

      @document
    end

    def resolve_imports!
      file_path_directory = File.dirname(file_path)

      @document = @document.gsub(/(?:require_relative\s+["'](.*)["'])/) do |path|
        fpath = Path[file_path]
        path = Path["#{path.gsub(/require_relative\s+["']/, "").rchop}.rb"]
        rpath = Path[fpath.dirname].join(path).to_s

        Resolver.new(rpath).code
      end
    end
  end
end
