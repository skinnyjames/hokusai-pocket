require_relative "./publisher"

module Hokusai
  # Public: Namespace for components provided by this library
  module Blocks; end
  # Public: A reactive UI component.
  #         Building block of an application. 
  #         Subclasses can be run with [Hokusai::Backend.run](/api/Hokusai/Backend#run)
  #         Blocks can be composed into other blocks templates
  # 
  # Examples
  #  
  #    class Counter < Hokusai::Block
  #      # create styles to use in templates
  #      style <<~EOF
  #      [style]
  #      additionStyles {
  #        background: rgb(214, 49, 24);
  #        cursor: "pointer";
  #      }
  #      additionLabel {
  #        size: 40;
  #        color: rgb(255,255,255);
  #      }
  #      subtractStyles {
  #        background: rgb(0, 85, 170);
  #        cursor: "pointer";
  #      }
  #      subtractLabel {
  #        size: 40;
  #        color: rgb(255, 255, 255);
  #      }
  #      EOF
  #      # define a template composed of other Hokusai::Block
  #      template <<-EOF
  #      [template]
  #        hblock { background="255,255,255" }
  #          label#count {
  #            :content="count.to_s"
  #            size="190" 
  #            :color="count_color"
  #          }
  #        hblock
  #          vblock#add { ...additionStyles @click="increment"}
  #            label { 
  #              content="Add"
  #              ...additionLabel 
  #            }
  #          vblock#subtract { ...subtractStyles @click="decrement" }
  #            label { 
  #              content="Subtract"
  #              ...subtractLabel 
  #            }
  #      EOF
  #      # map template names to Hokusai::Block
  #      uses(
  #        vblock: Hokusai::Blocks::Vblock,
  #        hblock: Hokusai::Blocks::Hblock,
  #        label: Hokusai::Blocks::Text,
  #      )
  #      #
  #      attr_accessor :count
  #      #
  #      def count_positive = count > 0
  #      def increment(event) = self.count += 1
  #      def decrement(event) = self.count -= 1
  #      def count_color = count.negative? ? [244, 0, 0] : [0, 0, 244]
  #      #
  #      def initialize(**args)
  #        @count = 0
  #        #
  #        super
  #      end
  #    end
  #
  class Block
    # Public: The node for this block
    # 
    # Returns [Hokusai::Node](/api/Hokusai/Node)
    attr_reader :node

    # Internal: The event publisher for this block
    # 
    # Returns [Hokusai::Publisher](/api/Hokusai/Publisher)
    attr_reader :publisher

    # Internal: Specified provisions for this block
    attr_reader :provides

    # Public: Provide a value to be injected into any of this block's descendants
    # 
    # name - a name that descandants can use to inject this provision (Symbol)
    # value - a name that maps to a method on this block (Symbol)
    # 
    # Examples
    # 
    #   provide :value, :method
    # 
    # Returns nothing
    def self.provide(name, value = nil, &block)
      if block_given?
        provides[name] = block
      else
        provides[name] = value
      end
    end

    # Internal: Class level provisions
    def self.provides
      @provides ||= {}
    end

    # Internal: Class level injections
    def self.injectables
      @injectables ||= []
    end

    # Public: Sets the template for this block
    #         Using a template string or the NodeBuilder DSL
    #
    # template - String template (optional if block provided)
    # block - DSL callback (optional if template provided)
    # 
    # Examples
    # 
    #   template <<-EOF
    #   [template]
    #     vblock
    #       text { content="Hello" size="10" }
    #   EOF
    #   
    #   template do
    #     child(Hokusai::Blocks::Vblock) do
    #       child(Hokusai::Blocks::Text) do
    #         prop :content do
    #           "Hello"
    #         end
    #         prop :size do
    #           10
    #         end
    #       end
    #     end
    #   end
    #   
    # Returns nothing
    def self.template(template = nil, &block)
      raise Hokusai::Error.new("Need a template or block") if template.nil? && block.nil?

      if template.nil?
        @build_template = block
      else
        @template = template
        @uses ||= {}
      end
    end

    # Internal: a NodeBuilder callback
    # 
    # Returns Proc or nil
    def self.build_template
      @build_template
    end

    # Public: Define a style template for this block.
    # 
    # template - a style template string or Hokusai::Style
    # 
    # Examples
    # 
    #   # Styles are named and map to props
    #   # on nodes/blocks
    #   #
    #   # Defined styles can also be written as "evented" for basic events.
    #   style <<-EOF
    #   [style]
    #     styleName {
    #       color: rgb(22,22,22);
    #       some_prop: 10.0;
    #       content: "Hello World";
    #       size: 14
    #       a_boolean: false
    #     }
    #     styleName@hover {
    #       color: rgb(222,22,22);
    #     }
    #   EOF
    # Returns nothing
    def self.style(template)
      case template
      when String
        @styles = ::Hokusai::Style.parse(template)
      when ::Hokusai::Style
        @styles = template
      end
    end

    # Deprecated: Sets the template for this block using a file
    #
    # path - a file path that contains a template
    # 
    # Returns nothing
    def self.template_from_file(path)
      @template = File.read(path)
    end

    # Internal: Fetches the template for this block
    #
    # @returns the template (Proc or String)
    def self.template_get
      @template || (raise Hokusai::Error.new("Must define template for #{self}"))
    end

    def self.styles_get
      @styles || {}
    end

    # Public: Defines blocks that this block uses in it's template. Must be defined if using a string template.
    #         Keys (Symbol) map to template node names, values map to a [Hokusai::Block](/api/Hokusai/Block).
    #         
    # kwargs - the key/value kwargs mapping
    #             :key - Symbol that maps to node
    #             :value - a Hokusai::Block.class
    #           
    # Examples
    #  
    #     uses(
    #       vblock: Hokusai::Blocks::Vblock,
    #       text: Hokusai::Blocks::Text
    #     )
    #     
    # Returns nothing
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

    # Public: Define a optional computed property with a default value
    # 
    # name - the name of the prop (Symbol)
    # kwargs - computed prop options
    #             :default - a default value if the prop is not provided (can be nil)
    #             :convert - a proc to convert a string to this type, or an object that responds_to #convert.  
    #                        eg [Hokusai::Outline.convert](/api/Hokusai/Outline#convert)
    #                        
    # Examples
    # 
    #   computed :radius, default: 10.0, convert: proc(&:to_f)
    #   
    #   computed :color, default: [22,22,22], convert: Hokusai::Color
    #   
    # Returns nothing
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

    # Public: Computed prop that is mandatory for this component
    # 
    # name - the name of the prop (Symbol)
    # 
    # Examples
    # 
    #   computed! :required_prop
    #   
    # Returns nothing
    # Raises Hokusai::Error if not provided
    def self.computed!(name)
      define_method(name.to_sym) do
        return node.meta.get_prop(name.to_sym) || (raise Hokusai::Error.new("Missing prop: #{name} on #{self.class}"))
      end
    end

    # Public: Inject a provision defined by an ancestor
    # 
    # name - the name of the provision (Symbol)
    # aliased - an alias/scoped name to use for this block (default name)
    # 
    # Examples
    # 
    #   inject :panel_offset
    #   
    #   inject :panel_offset, :local_offset
    #   
    # Returns nothing
    def self.inject(name, aliased = name)
      injectables << name

      define_method(aliased) do
        @injections[name]&.call
      end
    end

    # Public: Same as .inject but throws error if not provided
    def self.inject!(name, aliased)
      injectables << name

      define_method(aliased) do
        if provider = @injections[name]
          return provider.call
        end

        raise Hokusai::Error.new("No provision for #{name}")
      end
    end

    # Internal: Compile a string template or NodeBuilder proc
    # 
    # Returns [Hokusai::Node](/api/Hokusai/Node)
    def self.compile(name = "root", parent_node = nil)
      if build_template
        Node.build(name, parent_node, &build_template)
      else
        Node.parse(template_get, name.to_s, parent_node)
      end
    end

    # Public: Compile the template, register pub/sub and mount this block and it's children
    # 
    # name - a name for the ast node (default "root")
    # parent_node - a parent node that this block belongs to [Hokusai::Node](/api/Hokusai/Node)
    # options - hash of providers for this block (default: {})
    # 
    # Examples
    #   
    #   App.mount
    #   # returns #<App>
    # 
    # Returns Hokusai::Block
    def self.mount(name = "root", parent_node = nil, providers: {})
      compile(name, parent_node).mount(self, providers: providers)
    end

    # Public: Constructor for Hokusai::Block.  Can be overriden but must call `super`
    # 
    # args - kwargs for the construtor
    #         :node - a Hokusai::Node
    #         :providers - a hash of providers
    #         
    # Examples
    # 
    #   class App < Hokusai::Block
    #     #....
    #     def initialize(**args)
    #       @local_state = "hello"
    #       super
    #     end
    #   end
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

    # Public: a hash of provisions declared by this block
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

    # Public: Returns an array of children (Array(Hokusai::Block)) or nil
    def children?
      node.meta.children?
    end

    # Public: Returns an array of children (Array(Hokusai::Block)) or []
    def children
      node.meta.children!
    end

    # Internal: Updates the block from publisher
    def update
      node.meta.update(self)
    end

    # Public: Emits a custom event
    # 
    # name - name of the event (String)
    # args - a variable length splatted array of *args to pass to the subscriber
    # kwargs - any keyword args to pass to the subscriber
    # 
    # Examples
    #  
    #   emit("color_picked", Hokusai::Color.new(22,22,22))
    #   
    # Returns nothing
    def emit(name, *args, **kwargs)
      if portal = node.portal
        if event = portal.event(name.to_s)
          node.meta.publisher.notify(event.value.method, *args, **kwargs)
        end
      end
    end


    # Public: Opens the drawing API
    # 
    # block - a callback that is evaluated in the context of this instance
    # 
    # Examples
    #
    #   draw do
    #     # draw a green square
    #     rect(0.0, 0.0, 100.0, 100.0) do |command|
    #       command.color = Hokusai::Color.new(0, 0, 255)
    #     end
    #     # draw a circle with default properties
    #     circle(50.0, 50.0, 20.0) {}
    #   end
    # 
    # Returns nothing
    def draw(&block)
      instance_eval(&block)
    end

    def method_missing(name, *args,**kwargs, &block)
      if node.meta.commands.respond_to?(name)
        return node.meta.commands.send(name, *args, **kwargs, &block)
      end

      super
    end

    # Public: Same as draw but yields a [Hokusai::Commands](/api/Hokusai/Commands) as the callback parameter
    def draw_with
      yield node.meta.commands
    end

    # Public: makes an HTTP request on the libuv loop.  
    #         Note the response will be written to a temporary file
    # 
    # url - the url to request
    # opts - a hash of options
    #          :method - the HTTP method (GET, POST, etc)
    #          :headers - a hash of HTTP headers (ex: { 'Content-Type' => 'application/json' })
    #          :body - an optional body to send (String)
    # path: - a kwarg for the URI path
    # block - a callback that yields an HTTP response
    # 
    # Examples
    # 
    #   fetch("https://https://jsonplaceholder.typicode.com/todos/1", { method: "GET" }) do |res|
    #     # get the response code
    #     p res.code
    #     # get a JSON response as a ruby object
    #     p res.json
    #     # OR
    #     # get a response as a raw string
    #     p res.all
    #   end
    #   
    # Returns nothing
    def fetch(url, opts, path: "/", &block)
      instance_eval do
        req = Hokusai::Request.init(self, url)
        req.execute(path, opts, &block)
      end
    end

    # Internal: Execute the list of draw commands saved by the drawing API
    def execute_draw
      node.meta.commands.execute
      node.meta.commands.clear!
    end

    # Public: Render method.  Can be overriden but must yield the canvas parameter
    #                         in order to render this blocks template
    #
    # canvas - a [Hokusai::Canvas](/api/Hokusai/Canvas) with the suggested layout dimensions
    #
    # Returns nothing
    def render(canvas)
      yield(canvas)
    end

    # Public: Called when window is resized.  Override to change state in response to window resize
    # 
    # canvas - a [Hokusai::Canvas](/api/Hokusai/Canvas) with the new dimensions
    # 
    # Returns nothing
    def on_resize(canvas); end

    # Public: Dumps a String version of this block
    # 
    # show_props: - a kwarg for including props and events in the dump
    # 
    # Returns String
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

