require "prism"
require "tomparse"
require "fileutils"
require "json"

module Docs
  class GraphCyclicalError < StandardError; end

  class Graph
    attr_reader :nodes, :vertices

    def initialize(nodes = [], vertices = {})
      @nodes = nodes
      @vertices = vertices
    end

    def add(node, value)
      if vertex = vertices[node]
        return vertex
      end

      vertex = Vertex.new(name: node, value: value)
      vertices[node] = vertex
      nodes << node

      vertex
    end

    def upstreams(task)
      (filter([task]) - [task]).sort
    end

    def add_edge(from, to)
      return if from == to

      from_vertex = vertices[from]
      to_vertex = vertices[to]

      return if to_vertex.incoming[from]

      Graph::Visitor.visit(vertex: from_vertex, callback: ensure_non_cylical(to))

      from_vertex.has_outgoing = true

      to_vertex.incoming[from] = from_vertex
      to_vertex.incoming_names << from

      vertices[from] = from_vertex
      vertices[to] = to_vertex
    end

    def filter(names, result = names.dup)
      return result.uniq if names.empty?

      name = names.shift
      vertex = vertices[name]
      result = (result + vertex.incoming_names)

      result.concat filter((vertex.incoming_names - names), result)
      filter(names, result)
    end

    def ensure_non_cylical(to)
      ->(vertex, path) do
        if vertex.name == to
          raise GraphCyclicalError.new("Cyclical reference detected: #{to} <- #{path.join(" <- ")}")
        end
      end
    end
  end

  class Graph::Vertex
    attr_accessor :name, :value, :incoming, :incoming_names, :has_outgoing

    def initialize(name:, value:, incoming: {}, incoming_names: [], has_outgoing: false)
      @name = name
      @value = value
      @incoming = incoming
      @incoming_names = incoming_names
      @has_outgoing = has_outgoing
    end

    def has_outgoing?
      has_outgoing
    end
  end

  class Graph::Visitor
    def self.visit(vertex:, callback:, visited: {}, path: [])
      node = vertex.name
      incoming = vertex.incoming
      incoming_names = vertex.incoming_names

      return if visited[node]

      path << node
      visited[node] = true

      incoming_names.each do |name|
        visit(vertex: incoming[name], callback: callback, visited: visited, path: path)
      end

      callback.call(vertex, path)
      path.pop
    end
  end

  class EntityVisitor < Prism::Visitor
    attr_reader :classes, :modules, :methods, :constants, :stack, :visibility

    def initialize(src, visibility: [:public?])
      super()

      @src = src
      @visibility = visibility

      @classes = []
      @modules = []
      @methods = []
      @constants = []

      @modcache = {}
      @clscache = {}

      @stack = []
    end

    def visit_module_node(node)
      if @modcache[node.name]
        @stack << @modcache[node.name].dup
        super
        @stack.pop

        return
      end

      if stack.empty? && node.constant_path.full_name_parts.size > 1
        art = true
        node.constant_path.full_name_parts[0...-1].each do |name|
          @stack << @modcache[name]
        end
      end

      value = { module: node.name, stack: stack.dup }
      @stack << value.dup

      value[:doc] = TomParse.parse(annotate(node) || "")
      value[:methods] = []
      modules << value
      @modcache[node.name] = value

      super

      if art
        (node.constant_path.full_name_parts.size - 1).times do 
          @stack.pop
        end
      end

      @stack.pop
    end

    def visit_class_node(node)
      if @clscache[node.name]
        @stack << @clscache[node.name].dup
        super
        @stack.pop

        return
      end

      if stack.empty? || node.constant_path.full_name_parts.size > 1
        lstack = node.constant_path.full_name_parts[0...-1].map do |name|
          @clscache[name] || @modcache[name]
        end
      else
        lstack = stack.dup
      end

      value =  { class: node.name, superclass: superclass(node), stack: lstack }
      @stack << value.dup
      
      value[:doc] = TomParse.parse(annotate(node) || "")
      value[:methods] = []
      
      classes << value
      @clscache[node.name] = value

      super

      @stack.pop
    end

    def visit_call_node(node)
      if node.name == :attr_accessor && annotate(node) && node.arguments.child_nodes.size == 1
        doc = TomParse.parse(annotate(node) || "")
        if name = stack.last[:class]
          @clscache[name][:methods] << { method: "#{node.arguments.child_nodes.first.value}=", doc: doc, singleton: false }
        elsif name = stack.last[:module]
          @modcache[name][:methods] << { method: "#{node.arguments.child_nodes.first.value}=", doc: doc, singleton: false }
        end
      elsif node.name == :attr_reader && annotate(node) && node.arguments.child_nodes.size == 1
        doc = TomParse.parse(annotate(node) || "")
        if name = stack.last[:class]
          @clscache[name][:methods] << { method: "#{node.arguments.child_nodes.first.value}", doc: doc, singleton: false }
        elsif name = stack.last[:module]
          @modcache[name][:methods] << { method: "#{node.arguments.child_nodes.first.value}", doc: doc, singleton: false }
        end
      elsif (node.name == :computed || node.name == :computed!) && stack.last[:class] && stack.last[:superclass]&.join("::") == "Hokusai::Block"
        # get arguments
        hey = {}
        args = node.arguments.child_nodes
        prop_name = args.shift.value
        prop_things = args.each do |arg|
          arg.child_nodes.each do |child|
            key = child.key.value
            value = @src[child.value.start_character_offset..child.value.end_character_offset]
            hey[key] = value
          end
        end

        # rest should be keyword hash nodes
        @clscache[stack.last[:class]][:computeds] ||= []
        @clscache[stack.last[:class]][:computeds] << { name: node.name, prop: prop_name, opts: hey }
      elsif node.name == :emit && stack.last[:class] && stack.last[:superclass]&.join("::") == "Hokusai::Block"
        @clscache[stack.last[:class]][:emits] ||= []
        args = node.arguments.child_nodes
        prop_value = args.map { |arg| @src[arg.start_character_offset..arg.end_character_offset] }.join(" ")
        @clscache[stack.last[:class]][:emits] << prop_value
      end

      super
    end

    def visit_constant_write_node(node)
      super
    end

    def visit_def_node(node)
      doc = TomParse.parse(annotate(node) || "")
      keep = visibility.any? { |vis| doc.public_send(vis) }

      if keep
        singleton = node.receiver.class == ::Prism::SelfNode

        if name = stack.last[:class]
          @clscache[name][:methods] << { method: node.name, doc: doc, singleton: singleton }
        elsif name = stack.last[:module]
          @modcache[name][:methods] << { method: node.name, doc: doc, singleton: singleton }
        end
      end

      super
    end

    def superclass(node)
      return if node.superclass.nil?

      node.superclass.full_name_parts
    end

    def source(comment)
      @src[comment.location.start_offset, comment.location.length]
    end

    def annotate(node, join = "\n")
      if !node.leading_comments.empty?
        node.leading_comments.map {|comment| source(comment) }.join(join)
      end
    end
  end
end

def group_args(arguments)
  a = ""
  b = []
  arguments.each do |arg|
    if arg.name == :block
      b << "&block"
    else
      b << arg.name.to_s
    end
  end

  b.join(", ")
end

# clear api docs
FileUtils.rm_rf(File.join(__dir__, "docs", "api"))
source = File.read("#{__dir__}/mrblib/hokusai.rb")

file = Prism.parse(source)
file.attach_comments!

test = Docs::EntityVisitor.new(source, visibility: [:public?, :internal?, :deprecated?])
test.visit(file.value)


graph = Docs::Graph.new

test.modules.each do |mod|
  graph.add(mod[:module], mod)
end

test.classes.each do |klass|
  graph.add(klass[:class], klass)
end

test.modules.each do |mod|
  next if mod[:stack]&.empty? || mod.nil?

  [*mod[:stack], mod].reduce do |a, b|
    graph.add_edge(a[:module], b[:module])

    b
  end
end

test.classes.each do |mod|
  next if mod[:stack]&.empty?

  [*mod[:stack], mod].reduce do |a, b|
    graph.add_edge(a[:class] || a[:module], b[:class] || b[:module])

    b
  end
end

entities = graph.vertices.sort_by do |name, vertex|
  vertex.incoming_names.size
end

FileUtils.rm_rf(File.join(__dir__, "docs", "api"))
hash = {}

entities.each do |key, vertex|
  epath = graph.filter([key]).reverse
  path = File.join(__dir__, "docs", "api", *epath.map(&:to_s))

  stuff = epath.dup
  stuff.reduce(hash) do |memo, item|
    memo[item] ||= {}
    memo[item]
  end

  FileUtils.mkdir_p(File.dirname(path))

  value = vertex.value
  type = value[:module] ? "module" : "class"

  File.open("#{path}.md", "w") do |io|
    io.puts <<-EOF
---
layout: doc
---
    EOF

    badge = case value[:doc]
    when proc(&:internal?)
      '<Badge type="warning" text="internal" />'
    when proc(&:public?)
      '<Badge type="info" text="public" />'
    when proc(&:deprecated?)
      '<Badge type="danger" text="deprecated" />'
    end

    io << "# "
    io << "#{type} #{key}"
    if value[:superclass]
      io << " < #{value[:superclass].join("::")}"
    end
    io << " #{badge}"
    io.puts "\n"

    io << value[:doc].description

    if value[:computeds]
      io.puts "\n### Props\n\n"
      value[:computeds].uniq { |c| c[:prop] }.each do |computed|
        io.puts "* `#{computed[:name]} :#{computed[:prop]}, #{computed[:opts].map { |k,v| "#{k}: #{v}"}.join(" ")}`"
      end
      io.puts "\n\n"
    end

    if value[:emits]
      io.puts "\n### Emits\n\n"
      value[:emits].each do |emit|
        io.puts "* `emit(#{emit}`"
      end
      io.puts "\n\n"
    end

    unless value[:doc].examples.empty?
      io.puts "\n#### Examples\n\n"
      value[:doc].examples.each do |example|
        io.puts "```ruby"
        io.puts example
        io.puts "```"
      end
    end

    io.puts "\n\n"
    value[:methods].each do |method|
      badge = case method[:doc]
      when proc(&:internal?)
        '<Badge type="warning" text="internal" />'
      when proc(&:public?)
        '<Badge type="info" text="public" />'
      when proc(&:deprecated?)
        '<Badge type="danger" text="deprecated" />'
      end

      io << "## "
      io << "." if method[:singleton]
      io << "#" unless method[:singleton]
      io << method[:method].to_s.gsub("!", "\\!")
      unless method[:doc].arguments.empty?
        io << "(#{group_args(method[:doc].arguments)})"
      end
      io.puts " #{badge}"
      io.puts "\n"
      io.puts (method[:doc].description.split(/\n+/).map do |f| 
        if f =~ /\(\/api/
          f
        else
          "<p>#{f}</p>"
        end
      end.join("\n"))

      unless method[:doc].arguments.empty?
        io.puts "\n#### Arguments\n\n"
        method[:doc].arguments.each do |arg|
          io.puts "*  _#{arg.name}_ - #{arg.description.gsub("\n", "\n\n")}"
          unless arg.options.empty?
            arg.options.each do |opt|
              io.puts "   * #{opt.name} - #{opt.description}\n"
            end
          end
        end
      end
      
      unless method[:doc].examples.empty?
        io.puts "\n### Examples\n\n"
        method[:doc].examples.each do |example|
          io.puts "```ruby"
          io.puts example
          io.puts "```"
        end
      end

      unless method[:doc].returns.empty?
        io.puts "\n### Returns\n\n"
        method[:doc].returns.each do |ret|
          io.puts ret
        end
      end

      io.puts "\n\n"
    end
  end
end

def make_sidebar(hash, parents = [])
  children = []
  hash.keys.each do |key|
    nparents = parents.dup
    nparents.push(key)
    inner = make_sidebar(hash[key], nparents)
    res = {
      link: "api/#{nparents.join("/")}",
      text: key.to_s
    }

    res[:items] = inner unless inner.empty?
      
    children << res
  end
  children.sort_by { |f| f[:text] }
end

sidebar = make_sidebar(hash).to_json
replace = "//BEGINSIDEBAR\nconst sidebar = JSON.parse('#{sidebar}')\n//ENDSIDEBAR"

config_file = File.join(__dir__, "docs", ".vitepress", "config.js")

file = File.read(config_file)
file.gsub!(/\/\/BEGINSIDEBAR(.|\n)*\/\/ENDSIDEBAR/m, replace)
File.write(config_file, file)


