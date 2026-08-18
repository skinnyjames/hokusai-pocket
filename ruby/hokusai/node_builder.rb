module Hokusai
  # Internal: value used in loop directive callbacks
  class ProxyValue
    attr_accessor :value
    def initialize(value)
      @value = value
    end
  end

  # Public: Template DSL used in [Hokusai::Block.template](/api/Hokusai/Block.html#template-template-block)
  class NodeBuilder
    # Public: Builds an AST using a DSL
    # 
    # name - a Hokusai::Block.class
    # block - a DSL callback to build this AST
    def self.build(name, loopvar = nil, &block)
      ast = Ast.new
      ast.type = name

      obj = new(ast)
      obj.loopvar = loopvar
      
      obj.instance_eval(&block)
      
      obj.ast
    end

    attr_accessor :ast, :loopvar

    def initialize(ast)
      @ast = ast
      @loopvar = nil
      @counter = 0
    end

    def id(value)
      ast.id = value
    end

    # Public: Merge style defintions into this template
    # 
    # names - a splatted array of style names (*names)
    # 
    # Returns nothing
    def merge_styles(*names)
      names.each do |name|
        ast.style_list << name
      end
    end

    # Public: Declares a static prop
    # 
    # name - the prop key (Symbol)
    # value - a String containing the static prop value
    # 
    # Examples:
    #  
    #   static :size, "10"
    #   
    #   static :content, "'string'"
    #   
    # Returns nothing
    def static(name, value)
      raise Hokusai::Error.new("Static prop needs a string value") unless value.is_a?(String)

      func = Ast::Func.new(value, [])
      ast.props[name.to_s] = Ast::Prop.new(true, name, func)
    end

    # Public: declare a prop value.
    #         evaluates in the context of the Hokusai::Block
    # 
    # name - the prop name (Symbol)
    # value - a prop value (required if &block is nil)
    # block - a callback that returns the prop value
    # 
    # Returns nothing
    def prop(name, value = nil, &block)
      raise Hokusai::Error.new("Prop needs a value (symbol or block)") if block.nil? && value.nil?
      
      param = value.nil? ? block : value.to_s

      func = Ast::Func.new(param, [])
      ast.props[name.to_s] = Ast::Prop.new(true, name, func)
    end

    # Public: conditionally render this node if the provided method evaluates to true
    # 
    # method - name of a method on the calling Hokusai::Block
    #          (optional if passing block)
    # block - callback that should evaluate to a boolean
    #         (optional if passing method)
    #         
    # Returns nothing
    def show_if(method = nil, &block)
      raise Hokusai::Error.new("Need a method or block for show_if") if method.nil? && block.nil?

      if block.nil?
        cond = Ast::Func.new(method, [])
      else
        cond = Ast::Func.new(block, [])
      end

      ast.if = cond
    end

    # Public: defines a loop directive
    # 
    # klass - the Hokusai::Block to use
    # method - a method name (Symbol) that returns an Enumerable
    # block - callback for building this AST node
    #  
    # Examples
    # 
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
    #
    # Returns nothing
    def each_child(klass, method, &block)
      raise Hokusai::Error.new("each cannot be called at the top level currently.") unless ast.dynamic?

      unless block.parameters && block.parameters.first
        raise Hokusai::Error.new("each needs a block parameter")
      end

      var = block.parameters.first.last

      start = @counter
      child = NodeBuilder.build(klass) do
        proxy = ProxyValue.new(nil)
        ast.loop = Ast::Loop.new(var.to_s, method.to_s)
        ast.loop.start = start
        ast.loop.proxy = proxy
        instance_exec(proxy, &block)
      end

      child.siblingindex = @counter
      ast.children << child
    end

    # Public: Event handler subscription
    # 
    # event_name - name of event (Symbol | String)
    # block - callback that is passed the event parameters as block params
    # 
    # Examples
    # 
    #   on :click do |event|
    #     puts event.pos.x # clicked x coordinate
    #   end
    #
    # Returns nothing
    def on(event_name, &block)
      func = Ast::Func.new(block, [])
      ast.events[event_name.to_s] = Ast::Event.new(event_name, func)
    end

    # Public: declare a child block
    # 
    # klass - a Hokusai::Block
    # block - a callback to build this AST node
    #
    # Examples
    # 
    #   template do
    #     child(Hokusai::Blocks::Vblock) do
    #       child(Hokusai::Blocks::Text) do
    #         #...
    #       end
    #     end
    #   end 
    #
    # Returns nothing
    def child(klass, &block)
      child_ast = NodeBuilder.build(klass, &block)
      child_ast.siblingindex = @counter

      @counter += 1

      ast.children << child_ast
    end
  end
end