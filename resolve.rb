require "pathname"

class Resolver
  def self.write_to_file(path, filename)
    File.write(filename, new(path).code)
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
      resolved_path = Pathname.new(base_path.dirname).join(path).to_s

      Resolver.new(resolved_path).code
    end
  end
end

Resolver.write_to_file("#{__dir__}/ruby/hokusai.rb", "#{__dir__}/mrblib/hokusai.rb")
