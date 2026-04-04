module Hokusai
  class Ast
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

    class Func
      attr_accessor :method, :args
      def initialize(method, args)
        @method = method
        @args = args
      end

      def proc?
        @method.is_a?(Proc)
      end
    end

    class Event
      attr_accessor :name, :value
      def initialize(name, value)
        @name = name
        @value = value
      end
    end

    class Prop
      attr_accessor :name, :value, :computed, :built
      def initialize(computed, name, value, built: false)
        @name = name
        @value = value
        @computed = computed
        @built = built
      end

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

    def has_else_condition?
      !else_ast.nil?
    end

    def else_condition_active?
      !else_ast.nil? && else_active
    end
  
    def has_if_condition?
      !self.if.nil?
    end

    def loop?
      !self.loop.nil?
    end

    def slot?
      type == "slot"
    end

    def virtual?
      type == "virtual"
    end

    def dynamic?
      type.is_a?(Class)
    end

    def prop(name)
      props[name]
    end

    def event(name)
      events[name]
    end
  end
end
