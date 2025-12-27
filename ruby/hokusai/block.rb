require_relative "./publisher"

module Hokusai
  module Blocks; end
  # A UI Component
  #
  # Blocks are reusable and can be mounted in other blocks via templates
  #
  # Blocks have `props`` and emit `events`
  class Block
    attr_reader :node
    attr_reader :publisher
    attr_reader :provides

    def self.provide(name, value = nil, &block)
      if block_given?
        provides[name] = block
      else
        provides[name] = value
      end
    end

    def self.provides
      @provides ||= {}
    end

    def self.injectables
      @injectables ||= []
    end

    # Sets the template for this block
    #
    # @param [String] template to set
    def self.template(template)
      @template = template
      @uses ||= {}
    end

    def self.style(template)
      case template
      when String
        @styles = ::Hokusai::Style.parse(template)
      when ::Hokusai::Style
        @styles = template
      end
    end

    # Sets the template for this block
    # Uses a file
    #
    # @param [String] the filename to use
    def self.template_from_file(path)
      @template = File.read(path)
    end

    # Fetches the template for this block
    #
    # @return [String] the template
    def self.template_get
      @template || (raise Hokusai::Error.new("Must define template for #{self}"))
    end

    def self.styles_get
      @styles || {}
    end

    # Defines blocks that this block uses in it's template
    # Keys map to template node names, values map to a `Hokusai::Block`
    def self.uses(**args)
      args.each do |key, value|
        raise Hokusai::Error.new("#{key} value must be a Block, got #{value}") unless value.is_a?(Block.class)

        @uses[key.to_s.downcase] = value
      end
    end

    def self.use(type)
      if block_klass = @uses[type]
        block_klass
      else
        raise Hokusai::Error.new("Type #{type} is not used on #{self}")
      end
    end

    def self.computed(name, **args)
      define_method(name) do
        prop = node.meta.get_prop(name.to_sym)#props[name.to_sym]

        if prop.nil?
          prop = args[:default]
        end

        if prop.nil?
          return
        end

        case args[:convert]
        when Proc
          args[:convert].call(prop)
        when NilClass
          prop
        else
          if args[:convert].respond_to?(:convert)
            args[:convert].convert(prop)
          else
            raise Hokusai::Error.new("Prop converter #{args[:convert]} requires a convert method `.convert(value) => #{args[:convert]}`")
          end
        end
      end
    end

    def self.computed!(name)
      define_method(name.to_sym) do
        return node.meta.get_prop(name.to_sym) || (raise Hokusai::Error.new("Missing prop: #{name} on #{self.class}"))
      end
    end

    def self.inject(name, aliased = name)
      injectables << name

      define_method(aliased) do
        @injections[name]&.call
      end
    end

    def self.inject!(name, aliased)
      injectables << name

      define_method(aliased) do
        if provider = @injections[name]
          return provider.call
        end

        raise Hokusai::Error.new("No provision for #{name}")
      end
    end

    def self.compile(name = "root", parent_node = nil)
      Node.parse(template_get, name, parent_node)
    end

    def self.mount(name = "root", parent_node = nil)
      compile(name, parent_node).mount(self)
    end

    def initialize(**args)
      raise Hokusai::Error.new("Must supply node argument to #{self.class}.new") unless args[:node]

      @node = args[:node]
      @injections = {}

      self.class.injectables.each do |name|
        if value = args[:providers]&.[](name)
          @injections[name] = value
        end
      end
    end

    def providers
      self.class.provides.map do |k, v|
        if v.is_a?(Symbol)
          [k, -> { send(v) }]
        elsif v.is_a?(Proc)
          [k, v]
        else
          [k, -> { v }]
        end
      end.to_h
    end

    def children?
      node.meta.children?
    end

    def children
      node.meta.children!
    end

    def update
      node.meta.update(self)
    end

    def emit(name, *args, **kwargs)
      if portal = node.portal
        if event = portal.event(name)
          node.meta.publisher.notify(event.value.method, *args, **kwargs)
        end
      end
    end

    def draw(&block)
      instance_eval(&block)
    end

    def method_missing(name, *args,**kwargs, &block)
      if node.meta.commands.respond_to?(name)
        return node.meta.commands.send(name, *args, **kwargs, &block)
      end

      super
    end

    def draw_with
      yield node.meta.commands
    end

    def execute_draw
      node.meta.commands.execute
      node.meta.commands.clear!
    end

    def render(canvas)
      yield(canvas)
    end

    def on_resize(canvas); end

    def dump(level = 1, show_props: false)
      io = ""
      io << "#{self.class}"
      io << " if " if node.ast.has_if_condition?
      io <<  "(#{node.type})"

      if portal = node.portal
        io << ".#{portal.ast.classes.join(".")}"
      end

      io << "\n"

      if node.meta.props!.values.size > 0 && show_props
        io << "#{" " * level * 2}{\n"
        node.meta.props!.each do |key, value|
          io << "#{" " * level * 3}#{key} = #{value}\n"
        end

        unless node.portal.nil?
          node.portal.ast.events.each do |_, event|
            io << "#{" " * level * 3}@#{event.name} = #{event.value.method} #{!!node.portal.ast.event(event.name)}\n"
          end
        end
        io << "#{" " * level * 2}}\n"
      end

      if children.nil?
        io << "#{" " * level * 2}(no children)\n"
      else
        child_dump = children?&.map {|child| child.dump(level + 1, show_props: show_props) }
        io << "#{" " * level * 2}#{child_dump.join("#{" " * level * 2}") }\n"
      end

      io
    end
  end
end

