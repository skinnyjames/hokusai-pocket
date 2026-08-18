module Hokusai
  # Internal: Represents a template AST.  Can be made from a string template or
  #         using the [Hokusai::NodeBuilder](/api/Hokusai/NodeBuilder) DSL.
  #         
  class Ast
    # Internal: Represents a loop node.  Can be made from a string template or 
    #         using the [Hokusai::NodeBuilder](/api/Hokusai/NodeBuilder) DSL.
    #         You need to provide a unique key for the looped ast node
    #         Warning: Loops cannot currently be top level, nest them in another block - see examples.
    # 
    # Examples
    #   
    #   # Make loop from template
    #   #
    #   class Something < Hokusai::Block
    #     template <<-EOF
    #     [template]
    #     vblock
    #       [for="item in items"]
    #         text { :key="make_key(item, index)" :content="item" }
    #     EOF
    #     #
    #     # In string templates, the magic "index" variable is available
    #     # to pass to dynamic prop functions
    #     def make_key(item, index)
    #       "key-#{item}-#{index}"
    #     end
    #     #
    #     def items
    #       %w[foo bar baz]
    #     end
    #   end
    #
    #   # Make loop from the NodeBuilder DSL
    #   #
    #   class Something < Hokusai::Block
    #     template do
    #       child(Hokusai::Blocks::Vblock) do
    #         each_child(Hokusai::Blocks::Text, :items) do |item|
    #           prop :key do
    #             "key-#{item.value}"
    #           end
    #           #
    #           # item is a Hokusai::ProxyValue
    #           #
    #           prop :content do
    #             item.value
    #           end
    #         end
    #       end
    #     end
    #     #
    #     def items
    #       %w[foo bar baz]
    #     end
    #   end
    class Loop
      attr_accessor :var, :method, :proxy, :start, :lastlen
      def initialize(var, method)
        @var = var
        @method = method
        @proxy = nil
        @start = 0
        @lastlen = nil
      end
    end

    # Internal: Represents an AST event or dynamic prop value
    #          
    # Examples
    #
    #   node { @click="func" }
    #   
    #   # Computed props can take loop args
    #   node { :prop="func(arg, index)" }
    class Func
      attr_accessor :method, :args

      # Internal: Constructor for Func
      # 
      # method - the name of the func or a proc that the func evaluates to (String | Proc)
      # args - an array of argument names (String) for the func
      def initialize(method, args)
        @method = method
        @args = args
      end

      # Internal: Is the func made with Hokusai::NodeBuilder?
      # 
      # Returns boolean
      def proc?
        @method.is_a?(Proc)
      end
    end

    # Internal: Represents an AST event
    #          
    # Examples
    #   
    #   # string template usage
    #   node { @event="func" }
    # 
    #   # builder DSL usage
    #   on :event do |event|
    #     #...
    #   end
    class Event
      attr_accessor :name, :value

      # Internal: Constructor for the Func
      # 
      # name - the name of the event (String)
      # value - the func value for the event (Hokusai::Func)
      def initialize(name, value)
        @name = name
        @value = value
      end
    end

    # Internal: Represents an AST prop
    #          
    # Examples
    #
    #   # string template usage
    #   node { :prop="func" }
    #   
    #   # builder DSL usage
    #   prop :prop do
    #     "some-value"
    #   end
    class Prop
      attr_accessor :name, :value, :computed, :built

      # Internal: Constructor for the Func
      # 
      # name - the name of the event (String)
      # value - the func value for the event (Hokusai::Func)
      # computed - is this prop computed? (boolean)
      def initialize(computed, name, value, built: false)
        @name = name
        @value = value
        @computed = computed
        @built = built
      end

      # Internal: Is the prop computed?
      # 
      # Returns boolean
      def computed?
        @computed
      end
    end

    attr_reader :children, :siblings, :classes, :style_list
    attr_accessor :type, :id, :else_active, :loop, :if, :else_ast, 
                  :props, :events, :siblingindex

    def initialize
      @children = []
      @siblings = []
      @classes = []
      @style_list = []

      @props = {}
      @events = {}

      @loop = nil
      @if = nil
      @else_ast = nil
      
      @siblingindex = 0
      @type = nil
      @id = nil
      @else_active = false
    end

    # Internal: dumps a string representation of the ast
    # 
    # options - kwargs for modifying the dumped representation (**options)
    #           :show_props - show props and events in the dump (default false)
    #
    # Returns a string with the dumped ast
    def dump(level = 0, show_props: false)
      io = ""
      io << " if " if has_if_condition?
      io << " loop = #{loop.var} #{loop.method}" if loop?
      io <<  "(#{type})"
      io << "\n"

      if props.size > 0 && show_props
        io << "#{" " * level * 2}{\n"
        props.each do |key, value|
          io << "#{" " * level * 3}#{key} = #{value}\n"
        end

        events.each do |_, event|
          io << "#{" " * level * 3}@#{event.name} = #{event.value.method} #{!!event(event.name)}\n"
        end
        io << "#{" " * level * 2}}\n"
      end

      if children.empty?
        io << "#{" " * level * 2}(no children)\n"
      else
        child_dump = children&.map {|child| child.dump(level + 1, show_props: show_props) }
        io << "#{" " * level * 2}#{child_dump.join("#{" " * level * 2}") }\n"
      end

      io
    end
    
    def reset
      self.else_active = false
    end

    # Internal: Does this ast have an else condition?
    # 
    # Returns boolean
    def has_else_condition?
      !else_ast.nil?
    end

    # Internal: Is the else condition on this ast currently active?
    # 
    # Returns boolean
    def else_condition_active?
      !else_ast.nil? && else_active
    end
  
    # Internal: Does this ast have an if condition?
    # 
    # Returns boolean
    def has_if_condition?
      !self.if.nil?
    end

    # Internal: Does this ast have a loop?
    # 
    # Returns boolean
    def loop?
      !self.loop.nil?
    end

    # Internal: Is this ast a slot?
    # 
    # Returns boolean
    def slot?
      type == "slot"
    end

    # Internal: Is this ast a virtual node?
    # 
    # Returns boolean
    def virtual?
      type == "virtual"
    end

    # Internal: Is this ast made with Hokusai::NodeBuilder?
    # 
    # Returns boolean
    def dynamic?
      type.is_a?(Class)
    end

    # Internal: Get a prop by name (if one exists)
    # 
    # name - Name of the prop (String)
    # 
    # Returns [Hokusai::Ast::Prop](/api/Hokusai/Ast/Prop) or nil if none exists
    def prop(name)
      props[name]
    end

    # Internal: Get a event by name (if one exists)
    # 
    # name - Name of the event
    # 
    # Returns [Hokusai::Ast::Event](/api/Hokusai/Ast/Event) or nil if none exists
    def event(name)
      events[name]
    end
  end
end
