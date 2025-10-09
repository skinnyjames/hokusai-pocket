# # frozen_string_literal: true

# module Hokusai
#   # Wrapper for interacting with asts produced
#   # by LibHokusai
#   class Ast
#     def self.registry
#       @registry ||= {}
#     end

#     def self.get(template)
#       registry[template]
#     end

#     def self.save(template, ast)
#       registry[template] = ast
#     end

#     # A node representing a loop
#     class Loop
#       attr_reader :raw

#       def initialize(raw)
#         @raw = raw
#       end

#       # The loop variable
#       #
#       # eg [for="item in list"]
#       # the var is `item`
#       #
#       # @return [String]
#       def var
#         @name ||= raw[:name].freeze
#       end

#       # The loop method
#       #
#       # eg [for="item in list"]
#       # the method is `list`
#       #
#       # @return [String]
#       def method
#         @list_name ||= raw[:list_name].freeze
#       end
#     end

#     # A node representing a function
#     # call
#     class Func
#       attr_reader :raw

#       def initialize(raw)
#         @raw = raw
#       end

#       # Name of the func
#       #
#       # eg @target="run_this(one,two)"
#       # the name is `run_this`
#       #
#       # @return [String]
#       def method
#         @method ||= raw[:function].freeze
#       end

#       # Args of the func
#       #
#       # eg @target="run_this(one, two)"
#       # the args are [one, two]
#       #
#       # @return [Array(String)]
#       def args
#         @strargs ||= raw[:strargs]
#           .read_array_of_type(:pointer, :read_pointer, raw[:args_len])
#           .map(&:read_string).freeze
#       end
#     end

#     # A node representing an
#     # ast event
#     class Event
#       attr_reader :raw

#       # @param [LibHokusai::Event] raw event
#       def initialize(raw)
#         @raw = raw
#       end

#       # @return [String]
#       def name
#         @name ||= @raw[:name].freeze
#       end

#       # @return [Func?]
#       def value
#         @call ||= raw[:call]

#         return nil if @call.null?

#         @func ||= Func.new(@call)
#       end
#     end

#     # A node representing an ast prop
#     class Prop
#       attr_reader :raw

#       def initialize(raw)
#         @raw = raw
#       end

#       # @return [Bool] is this prop computed?
#       def computed?
#         raw[:computed]
#       end

#       # @return [String] the props name
#       def name
#         @name ||= raw[:name].freeze
#       end

#       # @return [Ast::Func] the props value
#       def value
#         @call ||= raw[:call]

#         return nil if @call.null?

#         @func ||= Func.new(@call)
#       end
#     end

#     attr_reader :raw
#     attr_accessor :updater, :parent, :target

#     def initialize(raw)
#       @raw = raw
#       @dirty = false
#       @children = nil
#       @siblings = nil
#       @classes = nil
#       @else_active = false
#     end

#     # @param [String] template the template to parse
#     # @param [String] type a name for this template (default root)
#     # @return [Hokusai::Ast]
#     def self.parse(template, type)
#       ast = LibHokusai.parse_template(type, template)
#       errored = LibHokusai.hoku_errored_ast(ast)

#       unless errored.null?
#         begin
#           raise Hokusai::Error.new(errored[:error]) 
#         ensure
#           # LibHokusai.hoku_ast_free(errored)
#         end
#       end

#       new(ast)
#     end

#     def style
#       @style ||= Style.parse_styles(raw[:styles]) unless raw[:styles].null?
#     end

#     def style_list
#       @style_list ||= begin
#         list = []

#         head = raw[:style_list]
#         until head.null?
#           list << head[:name]

#           head = head[:next]
#         end

#         list
#       end
#     end

#     # Marks this ast as dirty
#     # @return [Void]
#     def dirty!
#       @dirty = true
#     end

#     # Is this ast dirty?
#     # @return [Bool]
#     def dirty?
#       @dirty
#     end

#     # @return [Bool] is this node a slot?
#     def slot?
#       type == "slot"
#     end

#     # @return [Bool] is this node virtual?
#     def virtual?
#       type == "virtual"
#     end

#     # @return [Bool] does this node belong to a loop?
#     def loop?
#       @loop_condition = !raw[:loop].null? if @loop_condition.nil?

#       @loop_condition
#     end

#     # @return [Bool] does this node have an if condition?
#     def has_if_condition?
#       @if_condition = !raw[:cond].null? if @if_condition.nil?

#       @if_condition
#     end

#     # @return [Bool] does this node have an else condition?
#     def has_else_condition?
#       @else_condition = !raw[:else_relations].null? if @else_condition.nil?

#       @else_condition
#     end

#     # @return [Bool] is the else condition on this node currently active?
#     def else_condition_active?
#       has_else_condition? && @else_active == 1
#     end

#     # @param [Bool] else condition is active or not
#     def else_active=(val)
#       @else_active = val
#     end

#     # @return [Hokusai::Ast?] the ast of the else condition
#     def else_ast
#       return nil unless has_else_condition?

#       Ast.new(raw[:else_relations][:next_child])
#     end

#     # @return [Ast::Loop?] the loop that the ast belongs to
#     def loop
#       return nil unless loop?

#       @loop ||= Loop.new(raw[:loop])
#     end

#     # @return [Ast::Func?] the if condition of this ast
#     def if
#       @cond ||= raw[:cond]

#       return nil if @cond.null?

#       @call ||= @cond[:call]

#       return nil if @call.null?

#       @func ||= Func.new(@call)
#     end

#     # @return [String] the node type
#     def type
#       @type ||= raw[:type].nil? ? "(null)" : raw[:type]
#     end

#     # @return [String] the node id
#     def id
#       @id ||= raw[:id].nil? ? "(null)" : raw[:id]
#     end

#     # @return [Array<String>] the list of classes for this node
#     def classes
#       return @classes unless @classes.nil?

#       @classes = []
#       each_class do |child|
#         @classes << child
#       end

#       @classes
#     end

#     # @return [Array<Hokusai::Ast>] all the children of this node
#     def children
#       return @children unless @children.nil?

#       @children = []
#       each_child do |child|
#         @children << child
#       end

#       @children
#     end

#     # @return [Array<Hokusai::Ast>] all the siblings of this node
#     def siblings
#       return @siblings unless @siblings.nil?

#       @siblings = []

#       ast = raw[:relations][:next_sibling]
#       while !ast.null?
#         @siblings << Ast.new(ast)

#         ast = ast[:relations][:next_sibling]
#       end

#       @siblings
#     end

#     # @return [Array<Hokusai::Ast>] the children of the else condition for this node
#     def else_children
#       children = []

#       ast = raw[:else_relations][:next_child]
#       while !ast.null?
#         children << ast

#         ast = ast[:relations][:next_sibling]
#       end

#       children
#     end

#     # @return [Array<Ast::Prop>] all the props of this node
#     def props
#       return @props unless @props.nil?

#       @props = {}

#       each_prop do |prop|
#         @props[prop.name] = prop
#       end

#       @props
#     end

#     # @return [Array<Ast::Event>] all the events of this node
#     def events
#       return @events unless @events.nil?

#       @events = {}

#       each_event do |event|
#         @events[event.name] = event
#       end

#       @events
#     end

#     # Iterate over each child node of this ast
#     #
#     # @yield [Hokusai::Ast]
#     def each_child
#       ast = raw[:relations][:next_child]
#       i = 0

#       while !ast.null?
#         yield Ast.new(ast), i

#         i += 1
#         ast = ast[:relations][:next_sibling]
#       end
#     end

#     # Iterate over all class names for this ast
#     #
#     # @yield [String] the name of the class
#     def each_class
#       ast = raw[:class_list]
#       i = 0

#       while !ast.null?
#         yield(ast[:name], i)

#         i += 1
#         ast = ast[:next]
#       end
#     end

#     # Iterate over all events in this ast
#     #
#     # @yield [Hokusai::Ast::Event]
#     def each_event
#       i = FFI::MemoryPointer.new(:size_t)
#       i.write(:size_t, 0)
#       item = FFI::MemoryPointer.new :pointer

#       while LibHokusai.hashmap_iter(raw[:events], i, item)
#         event = item.get_pointer(0)
#         event = LibHokusai::HmlAstEvent.new(event)

#         yield Event.new(event)
#       end

#       item.free
#       i.free
#     end

#     # Iterate over all props in this ast
#     #
#     # @yield [Hokusai::Ast::Prop]
#     def each_prop
#       i = FFI::MemoryPointer.new :size_t
#       i.write(:size_t, 0)
#       item = FFI::MemoryPointer.new :pointer

#       while LibHokusai.hashmap_iter(raw[:props], i, item)
#         prop = item.get_pointer(0)
#         prop = LibHokusai::HmlAstProp.new(prop)

#         yield Prop.new(prop)
#       end

#       item.free
#       i.free
#     end

#     # Fetches a prop by name
#     # 
#     # @param [String] name of the prop
#     # @return [Ast::Prop?] the prop or nil
#     def prop(name)
#       props[name]
#     end

#     # Fetches an event by name
#     #
#     # @param [String] the name of the event
#     # @return [Ast::Event?] the event or nil
#     def event(name)
#       events[name]
#     end

#     def destroy
#       LibHokusai.hoku_ast_free(raw)
#     end

#     # dumps this ast to STDOUT
#     def dump
#       LibHokusai.hoku_dump(raw, 0)
#     end
#   end
# end