module Hokusai
  class ProxyValue
    attr_accessor :value
    def initialize(value)
      @value = value
    end
  end

  class NodeBuilder
    # returns mounted block
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

    def merge_styles(*names)
      names.each do |name|
        ast.style_list << name
      end
    end

    def static(name, value)
      raise Hokusai::Error.new("Static prop needs a string value") unless value.is_a?(String)

      func = Ast::Func.new(value, [])
      ast.props[name.to_s] = Ast::Prop.new(true, name, func)
    end

    def prop(name, value = nil, &block)
      raise Hokusai::Error.new("Prop needs a value (symbol or block)") if block.nil? && value.nil?
      
      param = value.nil? ? block : value.to_s

      func = Ast::Func.new(param, [])
      ast.props[name.to_s] = Ast::Prop.new(true, name, func)
    end

    def show_if(method = nil, &block)
      raise Hokusai::Error.new("Need a method or block for show_if") if method.nil? && block.nil?

      if block.nil?
        cond = Ast::Func.new(method, [])
      else
        cond = Ast::Func.new(block, [])
      end

      ast.if = cond
    end

    # define an loop directive
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

    def on(event_name, &block)
      func = Ast::Func.new(block, [])
      ast.events[event_name.to_s] = Ast::Event.new(event_name, func)
    end

    # create a new child and add it 
    # to the children of this node
    def child(klass, &block)
      child_ast = NodeBuilder.build(klass, &block)
      child_ast.siblingindex = @counter

      @counter += 1

      ast.children << child_ast
    end
  end
end