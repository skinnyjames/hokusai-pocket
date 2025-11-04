
module Hokusai
  class Error < StandardError; end
end
module Hokusai
  class Vec2
    attr_accessor :x, :y
    def initialize(x, y)
      @x = x
      @y = y
    end
  end
  
  class Rect
    attr_accessor :x, :y, :width, :height

    def initialize(x, y, width, height)
      @x = x
      @y = y
      @width = width
      @height = height
    end

    def intersect?(other)
      (x - other.x).abs <= ((width)) && (y - other.y).abs <= ((height))
    end

    def includes_y?(y)
      y > @y && y <= (@y + @height)
    end

    def includes_x?(x)
      x > @x && x <= (@x + @width)
    end

    def move_x_left(times = 1)
      @x - ((@width / 2) * times)
    end

    def move_x_right(times = 1)
      @x + ((@width / 2) * times)
    end

    def move_y_up(times = 1)
      @y - ((@height / 2) * times)
    end

    def move_y_down(times = 1)
      @y + ((@height / 2) * times)
    end
  end
end
module Hokusai
  class Outline 
    attr_reader :top, :left, :right, :bottom
    def initialize(top, right, bottom, left)
      @top = top
      @left = left
      @right = right
      @bottom = bottom
    end
  
    def self.default
      new(0.0, 0.0, 0.0, 0.0)
    end

    def hash
      [self.class, top, right, bottom, left].hash
    end

    def self.convert(value)
      case value
      when String
        if value.include?(",")
          convert(value.split(",").map(&:to_f))
        else
          convert(value.to_f)
        end
      when Float
        new(value, value, value, value)
      when Array
        new(value[0] || 0.0, value[1] || 0.0, value[2] || 0.0, value[3] || 0.0)
      when Outline
        value
      end
    end

    def present?
      top > 0.0 || right > 0.0 || bottom > 0.0 || left > 0.0
    end

    def uniform?
      top == right && top == bottom && top == left
    end
  end

  class Boundary < Outline
  end

  class Padding
    attr_reader :top, :left, :right, :bottom
    def initialize(top, right, bottom, left)
      @top = top
      @left = left
      @right = right
      @bottom = bottom
    end

    alias_method :t, :top
    alias_method :l, :left
    alias_method :r, :right
    alias_method :b, :bottom

    def width
      right + left
    end

    def height
      top + bottom
    end

    def self.convert(value)
      case value
      when String
        if value.include?(",")
          convert(value.split(",").map(&:to_f))
        else
          convert(value.to_i)
        end
      when Integer
        new(value, value, value, value)
      when Array
        new(value[0], value[1], value[2], value[3])
      when Padding
        value
      else
        raise Hokusai::Error.new("Unsupported conversion type #{value.class} for Hokusai::Padding")
      end
    end

    def hash
      [self.class, top, right, bottom, left].hash
    end
  end

  class Canvas
    attr_accessor :width, :height, :x, :y, :vertical, :reverse, :offset_y
    attr_reader :ox, :oy, :owidth, :oheight
    def initialize(width, height, ax = 0.0, ay = 0.0, vertical = true, reverse = false)
      @width = width
      @height = height
      @x = ax
      @y = ay
      @ox = ax
      @oy = ay
      @owidth = width
      @oheight = height
      @offset_y = 0.0
      @vertical = vertical
      @reverse = reverse
    end

    def reset(x, y, width, height, vertical: true, reverse: false)
      self.x = x
      self.y = y
      self.width = width
      self.height = height
      self.vertical = vertical
      self.reverse = reverse
      self.offset_y = 0.0
    end

    def to_bounds
      Hokusai::Rect.new(x, y, width, height)
    end

    def hovered?(input)
      input.hovered?(self)
    end

    def reverse?
      reverse
    end
  end

  # Color = Struct.new(:red, :green, :blue, :alpha) do
  class Color
    attr_accessor :red, :green, :blue, :alpha
    def initialize(red, green, blue, alpha = 255)
      @red = red.freeze
      @green = green.freeze
      @blue = blue.freeze
      @alpha = alpha.freeze
    end

    alias_method :r, :red
    alias_method :b, :blue
    alias_method :g, :green
    alias_method :a, :alpha

    def self.convert(value)
      case value
      when String
        value = value.split(",").map(&:to_i)
      when Array
      when Color
        return value
      else
        raise Hokusai::Error.new("Unsupported conversion type #{value.class} for Hokusai::Color")
      end

      new(value[0], value[1], value[2], value[3] || 255)
    end

    def to_shader_value
      [(r / 255.0), (g / 255.0), (b / 255.0), (a / 255.0)]
    end

    def hash
      [self.class, r, g, b, a].hash
    end
  end
end
# frozen_string_literal: true

module Hokusai
  class Touch
    attr_accessor :stack, :archive

    def initialize
      @stack = []
      @archive = []
      @tapped = false
      @swiped = false
      @pinched = false
      # @file = File.open("touch.log", "w")
    end

    def tapped?
      @tapped
    end

    def swiped?
      @swiped
    end

    def pinched?
      @pinched
    end

    def longtapping?
      log("#{touching?} - #{elapsed(token)}") if touching?
      touching? && elapsed(token) > 5
    end
    
    def longtapped?
      @longtapped
    end

    def touching?
      type == :down || type == :move
    end

    def duration
      if longtapping?
        return elapsed(token)
      end
      
      first, last = archive[-2..-1]

      last[:start] - first[:start]
    end

    def distance
      raise Hokusai::Error.new("Archive is empty") if archive.empty?
      first, last = archive[-2..-1]
      
      x = last[:x] - first[:x]
      y = last[:y] - first[:y]

      [x, y]
    end

    def direction
      raise Hokusai::Error.new("Archive is empty") if archive.empty?

      first, last = archive[-2..-1]
      
      x = last[:x] - first[:x]
      y = last[:y] - first[:y]

      if x.abs > y.abs
        # swiping left/right
        last[:x] > first[:x] ? :right : :left
      else
        # swiping up/down
        last[:y] > first[:y] ? :down : :up
      end
    end

    def angle
      raise Hokusai::Error.new("Archive is empty") if archive.empty?

      last, first = archive[-2..-1]
      
      x = last[:x] - first[:x]
      y = last[:y] - first[:y]

      (Math.atan2(x, y) * (-180 / Math::PI)).round(0).to_i
    end

    def log(str)
      # Thread.new do
      #   @file.write_nonblock("#{str}\n")
      # end
    end

    def record(finger, x, y)
      log("recording #{token}")
      if type == :down
        push(:move, finger, x, y)
        log("state is move")
      elsif type == :move
        stack.last[:x] = x
        stack.last[:y] = y
        
        log("updated state move")
      else 
        @longtapped = false
        @swiped = false
        @tapped = false
        push(:down, finger, x, y)
        log("state is down")
      end
    end

    def clear
      # log("clearing")
      if type == :move
        log("elapsed: #{elapsed(token)}")
        if elapsed(token) > 300 && within(10.0)
          @longtapped = true
          log('longtap')
        elsif within(10.0)
          @tapped = true
        else
          @swiped = true
          log('swipe')
        end
      elsif type == :down
        @tapped = true
        log('tap')
      else
        @longtapped = false
        @swiped = false
        @tapped = false
      end

      self.archive = stack.dup
      stack.clear
    end

    def elapsed(token)
      Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond) - token[:start]
    end

    def within(threshold)
      move = stack.last
      down = stack[-2]

      t1 = (move[:x] - down[:x]).abs
      t2 = (move[:y] - down[:y]).abs

      t1 < threshold && t2 < threshold
    end

    def pop
      stack.pop
    end

    def push(type, finger, x, y)
      log("push: #{type}")
      stack << {
        type: type,
        i: finger,
        x: x,
        y: y,
        start: Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond)
      }
    end

    def index
      token&.[](:finger)
    end

    def type
      token&.[](:type)
    end

    def token
      @stack.last
    end
  end
end
# frozen_string_literal: true

module Hokusai
  class MouseButton
    attr_accessor :up, :down, :clicked, :released

    def initialize
      @up = false
      @down = false
      @clicked = false
      @released = false
    end
  end

  class Mouse
    attr_reader :pos, :delta, :left, :right, :middle, :scroll
    attr_accessor :scroll_delta

    def initialize
      @pos = Vec2.new(0.0, 0.0)
      @delta = Vec2.new(0.0, 0.0)
      @scroll = 0.0
      @scroll_delta = 0.0
      @left = MouseButton.new
      @middle = MouseButton.new
      @right = MouseButton.new
    end

    def scroll=(val)
      last = scroll
      new_y = (last >= val) ? last - val : val - last
      self.scroll_delta = new_y
      @scroll = val
    end
  end
end

# frozen_string_literal: true

module Hokusai
  KEY_CODES = { 
    null: 0, apostrophe: 39, comma: 44, minus: 45, period: 46,
    slash: 47, zero: 48, one: 49, two: 50, three: 51, four: 52,
    five: 53, six: 54, seven: 55, eight: 56, nine: 57, semicolon: 59, 
    equal: 61, a: 65, b: 66, c: 67, d: 68, e: 69, f: 70, g: 71, h: 72, 
    i: 73, j: 74, k: 75, l: 76, m: 77, n: 78, o: 79, p: 80, q: 81, r: 82, 
    s: 83, t: 84, u: 85, v: 86, w: 87, x: 88, y: 89, z: 90, left_bracket: 91, 
    backslash: 92, right_bracket: 93, grave: 96, space: 32, escape: 256, 
    enter: 257, tab: 258, backspace: 259, insert: 260, delete: 261, right: 262, 
    left: 263, down: 264, up: 265, page_up: 266, page_down: 267, home: 268, end: 269, 
    caps_lock: 280, scroll_lock: 281, num_lock: 282, print_screen: 283, pause: 284, 
    f1: 290, f2: 291, f3: 292, f4: 293, f5: 294, f6: 295, f7: 296, f8: 297, 
    f9: 298, f10: 299, f11: 300, f12: 301, left_shift: 340, left_control: 341, 
    left_alt: 342, left_super: 343, right_shift: 344, right_control: 345, right_alt: 346, 
    right_super: 347, kb_menu: 348, kp_0: 320, kp_1: 321, kp_2: 322, kp_3: 323, 
    kp_4: 324, kp_5: 325, kp_6: 326, kp_7: 327, kp_8: 328, kp_9: 329, kp_decimal: 330, 
    kp_divide: 331, kp_multiply: 332, kp_subtract: 333, kp_add: 334, kp_enter: 335, 
    kp_equal: 336, back: 4, menu: 5, volume_up: 24, volume_down: 25
  }

  class Keyboard
    attr_accessor :shift, :control, :super, :alt
    attr_reader :keys, :pressed, :released

    def printable?
      [
        :space, :tab, :apostrophe, :comma, :minus, :period,
        :slash,
        :zero, :one, :two, :three, :four, :five, :six, 
        :seven, :eight, :nine, :semicolon, 
        :a, :b, :c, :d, :e, :f, :g, :h,
        :i, :j, :k, :l, :m, :n, :o, :p, :q, :r, 
        :s, :t, :u, :v, :w, :x, :y, :z,
      ].include?(symbol)
    end

    def initialize
      @shift = false
      @control = false
      @super = false
      @alt = false

      @keys = {}
      @pressed = []
      @released = []

      # populate the key states
      KEY_CODES.each do |symbol, code|
        @keys[symbol] = { code: code, symbol: symbol, up: false, down: false, pressed: false, released: false }
      end
    end

    def symbol
      pressed[0]&.[](:symbol)
    end

    def code
      pressed[0]&.[](:code)
    end

    def char
      pressed[0]&.[](:char)
    end

    def ctrl
      @control
    end

    def reset
      @pressed.clear
      @released.clear
      
      @shift = false
      @control = false
      @super = false
      @alt = false
    end


    def key_is_letter?(symbol)
      symbol == :a || symbol == :b || symbol == :c || symbol == :d ||
      symbol == :e || symbol == :f || symbol == :g || symbol == :h ||
      symbol == :i || symbol == :j || symbol == :k || symbol == :l ||
      symbol == :m || symbol == :n || symbol == :o || symbol == :p || 
      symbol == :q || symbol == :r || symbol == :s || symbol == :t ||
      symbol == :u || symbol == :v || symbol == :w || symbol == :x ||
      symbol == :y || symbol == :z
    end

    def char_code_from_key(key, shift)
      code = keys[key][:code]

      if !shift && key_is_letter?(key)
        code += 32 
      elsif shift && key == :apostrophe
        code = 34
      elsif shift && key == :comma
        code = 60
      elsif shift && key == :minus
        code = 95
      elsif shift && key == :period
        code = 62
      elsif shift && key == :slash
        code = 63
      elsif shift && key == :zero
        code = 41
      elsif shift && key == :one
        code = 33
      elsif shift && key == :two
        code = 64
      elsif shift && key == :three
        code = 35
      elsif shift && key == :four
        code = 36
      elsif shift && key == :five
        code = 37
      elsif shift && key == :six
        code = 94
      elsif shift && key == :seven
        code = 38
      elsif shift && key == :eight
        code = 42
      elsif shift && key == :nine
        code = 40
      elsif shift && key == :semicolon
        code = 58
      elsif shift && key == :equal
        code = 43
      elsif shift && key == :left_bracket
        code = 123
      elsif shift && key == :backslash
        code = 124
      elsif shift && key == :right_bracket
        code = 125
      elsif shift && key == :grave
        code = 126
      end

      return code if code <= 256
    end

    def set(key, down)
      if down
        case key
        when :left_shift, :right_shift
          @shift = true
        when :left_control, :right_control
          @control = true
        when :left_super, :right_super
          @super = true
        when :left_alt, :right_alt
          @alt = true
        end
      end

      if down && keys[key][:up]
        keys[key][:pressed] = true
        keys[key][:released]= false

        nkey = keys[key].dup
        nkey.merge!({ char: char_code_from_key(key, shift)&.chr })
        
        pressed << nkey
      elsif !down && keys[key][:down]
        keys[key][:pressed] = false
        keys[key][:released] = true

        nkey = keys[key].dup
        nkey.merge!({ char: char_code_from_key(key, shift)&.chr })

        released << nkey
      else
        keys[key][:pressed] = false
        keys[key][:released] = false
      end

      keys[key][:down] = down
      keys[key][:up] = !down
    end
  end
end


module Hokusai
  class Input
    attr_accessor :keyboard_override
    attr_reader :raw, :touch

    def hash
      [self.class, mouse.pos.x, mouse.pos.y, mouse.scroll, mouse.left.clicked, mouse.left.down, mouse.left.up].hash
    end

    def initialize
      @touch = nil
      @keyboard_override = false
    end

    def support_touch!
      @touch ||= Touch.new

      self
    end

    def keyboard
      @keyboard ||= Keyboard.new
    end

    def mouse
      @mouse ||= Mouse.new
    end

    def hovered?(canvas)
      pos = mouse.pos
      pos.x >= canvas.x && pos.x <= canvas.x + canvas.width && pos.y >= canvas.y && pos.y <= canvas.y + canvas.height
    end
  end
end

# frozen_string_literal: true

module Hokusai
  # Represents a patch to move a loop item
  # from one location to another
  class MovePatch
    attr_accessor :from, :to, :value, :delete

    def initialize(from:, to:, value:, delete: false)
      @from = from
      @to = to
      @value = value
      @delete = delete
    end
  end

  # Represents a patch to insert an item
  # into the loop list
  class InsertPatch
    attr_accessor :target, :value, :delete

    def initialize(target:, value:, delete: false)
      @target = target
      @value = value
      @delete = delete
    end
  end

  # Represents a patch to update the value
  # of a loop item at an index
  class UpdatePatch
    attr_accessor :target, :value

    def initialize(target:, value:)
      @target = target
      @value = value
    end
  end

  # Patch to delete a loop list item
  class DeletePatch
    attr_accessor :target

    def initialize(target)
      @target = target
    end
  end

  # A Differ for comparing one set of values to another
  #
  # When #patch is called, will yield various patches to
  # true up the old values with the new values.
  class Diff
    attr_reader :before, :after, :insertions

    def initialize(before, after)
      @before = before
      @after = after
      @insertions = {}
    end

    def map(list)
      memo = {}
      list.each_with_index do |(key, value), index|
        memo[key] = { value: value, index: index }
      end

      memo
    end

    def patch
      i = 0
      deletions = 0
      mapbefore = map(before)
      mapafter = map(after)

      while i < after.size
        # left            right
        # [d, a, c]     [(c), e, a, b]
        #
        # 1. [c, a]     [c, (e), a]
        #
        # 2. [c, e, a]   [c, e, b, (a),]
        #
        # 3. [c, e, b, a]
        #
        # is value (c) in left?
        # yes ->
        #   is left[0] (a) in right?
        #     yes -> move c to 0, move a to 2
        #     no -> delete a, move c to 0
        #
        akey, value = after[i]              # b
        ckey, current = before[i] || nil    # a

        if bi = mapbefore.delete(akey) # 2
          if bi[:index] != i              # true (2 != 0)
            if mapafter[ckey] # true
              # move a to 2
              before[bi[:index]] = [ckey, current] # before[2] = a
              # update index
              mapbefore[ckey] = { index: bi[:index], value: current }

              # move c to 0
              yield MovePatch.new(from: bi[:index], to: i, value: bi[:value])
            else
              yield MovePatch.new(from: bi[:index], to: i, value: bi[:value], delete: true)
              mapbefore[ckey] = nil
              deletions += 1
              # next
            end
          elsif value != current
            yield UpdatePatch.new(target: i, value: value)
          end
        else # insert logic
          if mapafter[ckey]
            before[i + 1] = [ckey, current]
            mapbefore[ckey] = { index: i + 1, value: current }

            yield InsertPatch.new(target: i, value: value)
          else
            yield InsertPatch.new(target: i, value: value, delete: true)
            mapbefore[ckey] = nil

          end
        end

        i += 1
      end

      mapbefore.values.each do |value|
        next if value.nil?

        yield DeletePatch.new(value[:index]) unless value[:index].nil?
      end
    end
  end
end

module Hokusai
  module Mounting
    class LoopContext
      attr_reader :table
      def initialize
        @table = {}
      end

      def add_entry(var, value)
        table[var] = value
      end

      def send_target(target, func)
        args = func.args.map do |arg|
          table[arg]
        end

        target.send(func.method, *args)
      end
    end

    class LoopEntry
      INDEX_KEY = "index".freeze

      def initialize(mount_entry)
        @entry = mount_entry
      end

      def ast
        @entry.ast
      end

      def block
        @entry.block
      end
      
      def target
        @entry.target
      end

      def parent
        @entry.parent
      end

      def mount_providers
        @entry.mount_providers
      end

      def register
        child_block_class = target.class.use(ast.type)
        values = target.send(ast.loop.method)

        unless values.is_a?(Enumerable)
          raise Hokusai::Error.new("Loop directive `#{ast.loop.method}` on #{target.class} must return an Enumerable")
        end

        entries_to_return = []
        secondary_entries = []

        values.each_with_index do |value, index|
          ctx = LoopContext.new
          ctx.add_entry(ast.loop.var, value)
          ctx.add_entry(INDEX_KEY, index)

          if ast.has_if_condition?
            if ast.if.args.size > 0
              ctx.send_target(target, target.if)
            else
              condition = target.send(ast.if.method)
            end

            next if condition
          end

          portal = Node.new(ast)
          node = child_block_class.compile(ast.type, portal)
          child_block = child_block_class.new(node: node, providers: mount_providers)
          child_block.node.add_styles(target.class)
          child_block.node.add_props_from_block(target, context: ctx)
          child_block.node.meta.set_prop(ast.loop.var.to_sym, value)
          child_block.node.meta.publisher.add(target)

          UpdateEntry.new(child_block, block, target).register(context: ctx, providers: mount_providers.merge(child_block.providers))

          block.node.meta << child_block

          node.ast.children.each_with_index do |child, idx|
            entries_to_return << MountEntry.new(index, child, child_block, child_block, child_block, context: nil, providers: mount_providers.merge(child_block.providers))
          end

          siblings = []
          portal.ast.children.each_with_index do |child, idx|
            siblings << MountEntry.new(idx, child, child_block, child_block, target, context: ctx, providers: mount_providers.merge(child_block.providers))
          end

          secondary_entries << siblings
        end

        update_loop

        [entries_to_return, secondary_entries]
      end

      def update_loop
        block.node.meta.on_update(target) do |ublock, uparent, utarget|
          values = utarget.send(ast.loop.method)

          unless values.is_a?(Enumerable)
            raise Hokusai::Error.new("Loop directive `#{ast.loop.method}` on #{target.class} must return an Enumerable")
          end

          key_prop = ast.props["key"]

          raise Hokusai::Error.new("Loop children must have a :key method defined") if key_prop.nil?

          key_ctx = LoopContext.new

          new_values = []

          index_key = "index".freeze
          values.each_with_index do |value, index|
            key_ctx.add_entry(ast.loop.var, value)
            key_ctx.add_entry(index_key, index)

            if key_prop.value.args.size > 0
              key = key_ctx.send_target(utarget, key_prop.value)
            elsif key_ctx.table[key_prop.value.method]
              key = key_ctx.table[key_prop.value.method]
            else
              key = utarget.send(key_prop.value.method)
            end

            new_values << [key, value]
          end

          previous_values = []
          children = []
          loop_var = ast.loop.var.to_sym

          ublock.children?&.each do |child|
            if key = child.node.meta.get_prop(:key)
              raise Hokusai::Error.new("Loop children must use :key field") unless key

              previous_values << [key, child.node.meta.get_prop(loop_var)]
            end

            children << child
          end

          if new_values == previous_values
            next
          end

          Diff.new(previous_values, new_values).patch do |patch|
            case patch
            when UpdatePatch
              ctx = LoopContext.new
              ctx.add_entry("index", patch.target)
              ctx.add_entry(ast.loop.var, patch.value)
              children[patch.target].node.add_styles(target.class)
              children[patch.target].node.add_props_from_block(target, context: ctx)

              UpdateEntry.new(children[patch.target], uparent, utarget).register(context: ctx)
            when MovePatch
              if patch.delete
                from = children[patch.from]
                children[patch.to] = from
                children[patch.from].send(:before_destroy) if children[patch.from].respond_to? :before_destroy
                children[patch.from].node.destroy
                children[patch.from] = nil
              else
                from = children[patch.from]
                to = children[patch.to]

                children[patch.to] = from
                children[patch.from] = to
              end

              ctx = LoopContext.new
              ctx.add_entry(INDEX_KEY, patch.to)
              children[patch.to].node.meta.props.each do |k, v|
                ctx.add_entry(k.to_s, v)
              end

              children[patch.to].node.add_styles(target.class)
              children[patch.to].node.add_props_from_block(target, context: ctx)
            when InsertPatch
              target_ast = ast
              ctx = LoopContext.new
              ctx.add_entry(INDEX_KEY, patch.target)
              ctx.add_entry(ast.loop.var, patch.value)

              if ast.has_if_condition?
                if ast.if.args.size > 0
                  condition = ctx.send_target(target, ast.if.method)
                else
                  condition = target.send(ast.if.method)
                end

                if !condition && ast.has_else_condition?
                  target_ast = ast.else_ast
                elsif !condition
                  children[patch.target].send(:before_destroy) if children[patch.target].respond_to? :before_destroy
                  children[patch.target].node.destroy
                  children[patch.target] = nil
                  next
                end
              end

              child_block_class = utarget.class.use(target_ast.type)
              portal = Node.new(ast)
              node = child_block_class.compile(target_ast.type, portal)
              node.add_props_from_block(target, context: ctx)
              child_block = NodeMounter.new(node, child_block_class).mount(context: nil, providers: mount_providers.merge(ublock.providers))
              child_block.node.add_styles(target.class)
              child_block.node.meta.publisher.add(target)

              if patch.delete
                children[patch.target] = child_block
              else
                children.insert(patch.target, child_block)
              end
            when DeletePatch
              children[patch.target].send(:before_destroy) if children[patch.target].respond_to? :before_destroy
              children[patch.target].node.destroy
              children[patch.target] = nil
              # TODO: update rest of block props
            end
          end

          ublock.node.meta.children = children.reject(&:nil?)
        end
      end
    end
  end
end

module Hokusai
  module Mounting
    class MountEntry
      attr_reader :block, :parent, :ast, :target, :index, :ctx

      def initialize(index, ast, block, parent, target = parent, context: nil, providers: {})
        @index = index
        @ast = ast
        @block = block
        @parent = parent
        @target = target
        @providers = providers
        @ctx = context
      end

      def mount_providers
        @providers
      end

      def loop?
        ast.loop?
      end

      def virtual?
        ast.virtual?
      end

      def slot?
        ast.slot?
      end

      def debug
        str = <<~EOF
          #{block.class} | #{ast.type} (#{index})
          #{block.node.ast.children.map(&:type)}
          providers: #{@providers.map {|k,v| k }.join(", ")}
          parent: #{parent.class}
          target: #{target.class}\n\n
        EOF
      end

      def with_block(new_block, supercede_parent: false)
        parent_block = supercede_parent ? block : parent

        MountEntry.new(index, ast, new_block, parent_block, target, context: ctx, providers: mount_providers)
      end

      def mount(context: nil, providers: {})
        klass = target.class.use(ast.type)
        portal = Node.new(ast)

        node = klass.compile(ast.type, portal)
        node.add_styles(target.class)
        node.add_props_from_block(target, context: context || ctx)

        # handle provides / dependency injection
        child_block = klass.new(node: node, providers: providers.merge(mount_providers))
        child_block.node.meta.publisher.add(target) # todo
        UpdateEntry.new(child_block, block, target).register(context: context || ctx, providers: providers.merge(mount_providers))

        block.node.meta << child_block

        yield child_block

        block.send(:on_mounted) if block.respond_to?(:on_mounted)
      end
    end
  end
end
module Hokusai
  module Mounting
    class UpdateEntry
      attr_reader :block, :parent, :target

      def initialize(block, parent, target)
        @block = block
        @parent = parent
        @target = target
      end

      def meta
        block.node.meta
      end

      def register(context: nil, providers: {})
        meta.on_update(target) do |ublock, uparent, utarget|
          if portal = ublock.node.portal
            portal.ast.children.each_with_index do |child, index|
              next unless child.has_if_condition?

              child_present = ->(child, elsy) do
                meta.has_ast?(child, index, elsy)
              end 

              if child.if.args.size > 0
                visible = utarget.send(child.if.method, context: context)
              else
                visible = utarget.send(child.if.method)
              end

              child_block_klass = target.class.use(child.type)

              if !!visible
                if child.else_condition_active?
                  meta.child_delete(index) if child_present.call(child, false)
                  child.else_active = 0
                end

                unless child_present.call(child, true)
                  portal = Node.new(child, Node.new(child))
                  node = child_block_klass.compile("root", portal)
                  node.add_styles(target.class)
                  node.add_props_from_block(target, context: context)
                  node.meta.publisher.add(target)

                  stack = []
                  child.children.each_with_index do |ast, ast_index|
                    stack << MountEntry.new(ast_index, ast, ublock, uparent, utarget, providers: providers)
                  end

                  child_block = NodeMounter.new(node, child_block_klass, [stack], previous_providers: providers).mount(context: context, providers: providers)

                  UpdateEntry.new(child_block, block, target).register(context: context, providers: providers)
                  meta.children!.insert(index, child_block)

                  child_block.send(:before_updated) if child_block.respond_to?(:before_updated)
                  child_block.update
                  child.else_active = 0
                end
              elsif !visible
                if !child.has_else_condition? || (child.has_else_condition? && !child.else_condition_active?)
                  if (child_present.call(child, true))
                    meta.child_delete(index)
                  end
                end

                if child.has_else_condition? && !child.else_condition_active?
                  portal = Node.new(child.else_ast, Node.new(child))
                  else_child_block_klass = target.class.use(child.else_ast.type)

                  node = else_child_block_klass.compile(child.else_ast.type, portal)
                  node.add_styles(utarget.class)
                  node.add_props_from_block(utarget, context: context)
                  node.meta.publisher.add(utarget)
                  
                  stack = []
                  child.else_ast.children.each_with_index do |ast, ast_index|
                    stack << MountEntry.new(ast_index, ast, ublock, uparent, utarget, providers: providers)
                  end

                  child_block = NodeMounter.new(node, else_child_block_klass, [stack], previous_providers: providers).mount(context: context, providers: providers)
                  UpdateEntry.new(child_block, block, utarget).register(context: context, providers: providers)
                  meta.children!.insert(index, child_block)

                  child_block.send(:before_updated) if child_block.respond_to?(:before_updated)
                  child_block.update
                  child.else_active = 1
                end
              end
            end
          end

          ublock.send(:before_updated) if ublock.respond_to?(:before_updated)
          ublock.node.add_styles(utarget.class)
          ublock.node.add_props_from_block(utarget, context: context)
          ublock.send(:after_updated) if ublock.respond_to?(:after_updated)
        end
      end
    end
  end
end

module Hokusai
  class NodeMounter
    attr_accessor :primary_stack, :secondary_stack
    attr_reader :root

    def initialize(node, klass, secondary_stack = [], previous_target = nil, previous_providers: {})
      @root = klass.new(node: node, providers: previous_providers)

      raise Hokusai::Error.new("Root #{klass} doesn't have a node.  Did you remember to call `super`?") if @root.node.nil?

      @secondary_stack = secondary_stack
      @primary_stack = []

      node.ast.children.each_with_index do |child, index|
        primary_stack << Mounting::MountEntry.new(index, child, root, root, previous_target || root, providers: root.providers)
      end
    end

    def mount(context: nil, providers: {})
      mount_providers = providers.merge(root.providers)

      while entry = primary_stack.shift
        next if entry.virtual?

        if entry.loop?
          entries, secondary_entries = Mounting::LoopEntry.new(entry).register

          self.primary_stack = entries + primary_stack
          self.secondary_stack = secondary_entries + secondary_stack

          next
        end

        if entry.ast.has_if_condition?
          next unless entry.target.send(entry.ast.if.method)
        end

        if entry.slot?
          while siblings = secondary_stack.shift
            next if siblings.empty?

            continue = false

            while sibling_entry = siblings.pop
              # if we encounter a nested slot, we will
              # add the current siblings to the end of the next
              # non-empty slot sibling group
              # and continue processing slots
              if sibling_entry.slot?
                continue = true

                secondary_stack.each_with_index do |previous_siblings, i|
                  next if previous_siblings.empty?

                  secondary_stack[i] = siblings +  previous_siblings
                  siblings.clear

                  break
                end
              else
                primary_stack.unshift sibling_entry.with_block(entry.block)
              end
            end

            next if continue
            break
          end

          next
        end

        entry.mount(context: context, providers: mount_providers) do |child_block|
          new_mount_providers =  mount_providers
                                  .merge(entry.mount_providers)
                                  .merge(entry.block.providers)
                                  .merge(child_block.providers)

          # create a subentry to register event handling and prop passing
          Mounting::UpdateEntry.new(child_block, entry.block, entry.target).register(context: context || entry.ctx, providers: new_mount_providers)

          # Populate the secondary stack with the portal children
          # this stack will be used to populate any slots in the primary_stack
          items = []

          entry.ast.children.each_with_index do |child, child_index|
            child.has_if_condition?

            items << Mounting::MountEntry.new(child_index, child, child_block, entry.parent, entry.target, context: entry.ctx, providers: new_mount_providers)
          end

          secondary_stack.unshift items

          # populate the primary stack with the newly compiled
          # ast from child_block
          primary_items = []

          child_block.node.ast.children.each_with_index do |child, child_index|
            primary_items << Mounting::MountEntry.new(child_index, child, child_block, child_block, context: entry.ctx, providers: new_mount_providers)
          end

          self.primary_stack = primary_items + primary_stack
        end
      end

      root
    end
  end
end
module Hokusai
  # An event emitter
  class Publisher
    attr_reader :listeners

    def initialize(listeners = [])
      @listeners = listeners
    end

    # Adds a listener that subscribes
    # to events emitted
    # by this publisher
    #
    # @param [Hokusai::Block] listener
    def add(listener)
      listeners << listener
    end

    # emits `event` with `**args`
    # to all subscribers
    # @see
    # @param [String] name the event name
    # @param [**args] the args to emit
    def notify(name, *args, **kwargs)
      listeners.each do |listener|
        raise Hokusai::Error.new("No target `##{name}` on #{listener.class}") unless listener.respond_to?(name)

        listener.send(name, *args, **kwargs)
      end
    end
  end
end

module Hokusai
  class Meta
    attr_reader :focused, :parent, :target, :updater,
                :props, :publisher

    def commands
      @commands ||= Commands.new
    end

    def initialize
      @focused = false
      @parent = nil
      @target = nil
      @updater = nil
      @props = nil
      @publisher = Publisher.new
      @children = nil
    end

    def node_count
      count = children?&.size || 0

      children?&.each do |child|
        count += child.node.meta.node_count
      end

      count
    end

    def get_child?(index)
      return nil if @children.nil?

      get_child(index)
    end

    def children=(values)
      @children = values
    end

    def children?
      return nil if @children.nil?

      @children
    end

    def <<(child)
      children! << child
    end

    def get_child(index)
      children![index]
    end

    def set_child(index, value)
      children![index] = value
    end

    def children!
      @children ||= []
    end

    def props!
      @props ||= {}
    end

    def get_prop?(name)
      return nil if @props.nil?

      get_prop(name)
    end

    def set_prop(name, value)
      @props ||= {}

      @props[name] = value
    end

    def get_prop(name)
      @props ||= {}

      @props[name]
    end

    def focus
      @focused = true

      children?&.each do |child|
        child.node.meta.focus
      end
    end

    def blur
      @focused = false

      children?&.each do |child|
        child.node.meta.blur
      end
    end

    def on_update(target, &block)
      @target = target
      @updater = block
    end

    def update(block)
      if target_block = target
        if updater_block = updater
          block.before_updated if block.respond_to?(:before_updated)

          updater_block.call(block, target_block, target_block)

          # reset all styles
          block.after_updated if block.respond_to?(:after_updated)
        end
      end
    end

    def has_ast?(ast, index, elsy = false)
      if elsy
        if portal = children![index]&.node&.portal
          return portal.ast.object_id == ast.object_id
        end
      else
        if portal = children![index]&.node&.portal&.portal
          return portal.ast.object_id == ast.object_id
        end
      end

      false
    end

    def child_delete(index)
      if child = children![index]
        child.before_destroy if child.respond_to?(:before_destroy)
        child.node.destroy

        children!.delete_at(index)
      end
    end
  end
end

module Hokusai
  class Node
    attr_reader :ast, :node, :uuid, :meta, :portal

    def self.parse(template, name = "root", parent = nil)
      ast = Ast.parse(template, name)

      new(ast, parent)
    end

    def slot?
      ast.slot?
    end

    def type
      ast.type
    end

    def event(name)
      ast.event(name)
    end

    def initialize(ast, portal = nil)
      @ast = ast
      @portal = portal
      # @uuid = SecureRandom.hex(6).freeze
      @meta = Meta.new
    end

    def mount(klass)
      NodeMounter.new(self, klass).mount
    end

    def destroy
      # meta.children?&.each do |child|
      #   child.node.destroy
      # end
      #
      # ast.destroy
    end

    def emit(name, **args)
      if node = portal
        if event = node.event(name)
          meta.publisher.notify(event.value.name, **args)
        else
          raise Hokusai::Error.new("Invocation failed: @#{name} doesn't exist on #{node.type}")
        end
      end
    end

    def add_evented_styles(klass, event_name)
      return if portal.nil?

      portal.ast.style_list.each do |style_name|
        style = klass.styles_get[style_name]
        
        if style.nil?
          raise ArgumentError.new("Style (#{style_name}) doesn't exist in the styles for this block #{klass} - #{klass.styles_get.keys}")
        end

        if sattr = style[event_name]
          sattr.each do |key, value|
            meta.set_prop(key.to_sym, value)
          end
        end
      end
    end

    def add_styles(klass)
      return if portal.nil?

      portal.ast.style_list.each do |style_name|
        style = klass.styles_get[style_name]

        raise Hokusai::Error.new("Style #{style_name} doesn't exist in the styles for this block #{klass} - #{klass.styles_get.keys}") if style.nil?

        if sattr = style["default"]
          sattr.each do |key, value|
            meta.set_prop(key.to_sym, value)
          end
        end
      end
    end

    def add_props_from_block(parent, context: nil)
      if local_portal = portal
        if block = parent
          local_portal.ast.props.each do |_, prop|
            method = prop.value.method

            case prop.computed?
            when true
              if prop.value.args.size > 0 && context
                value = context.send_target(block, prop.value)
              elsif context&.table&.[](method)
                value = context.table[method]
              else
                value = block.instance_eval(method)
              end
            else
              value = method
            end

            meta.set_prop(prop.name.to_sym, value)
          end
        end
      end
    end
  end
end
module Hokusai
  # An event emitter
  class Publisher
    attr_reader :listeners

    def initialize(listeners = [])
      @listeners = listeners
    end

    # Adds a listener that subscribes
    # to events emitted
    # by this publisher
    #
    # @param [Hokusai::Block] listener
    def add(listener)
      listeners << listener
    end

    # emits `event` with `**args`
    # to all subscribers
    # @see
    # @param [String] name the event name
    # @param [**args] the args to emit
    def notify(name, *args, **kwargs)
      listeners.each do |listener|
        raise Hokusai::Error.new("No target `##{name}` on #{listener.class}") unless listener.respond_to?(name)

        listener.send(name, *args, **kwargs)
      end
    end
  end
end

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
        @styles = Hokusai::Style.parse(template)
      when Hokusai::Style
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


# frozen_string_literal: true

class Hokusai::Commands
  class Base
    def self.on_draw(&block)
      @draw = block
    end

    def self.draw
      @draw
    end

    def draw
      raise Hokusai::Error.new("No draw callback made for #{self.class}") if self.class.draw.nil?

      self.class.draw.call(self.freeze)
    end

    def after_draw(canvas)
    end
  end
end
module Hokusai
  class Commands::Circle < Commands::Base
    attr_reader :x, :y, :radius, :color, :outline_color,
                :outline

    def initialize(x, y, radius)
      @x = x
      @y = y
      @radius = radius
      @color = Color.new(255, 255, 255, 255)
      @outline_color = Color.new(0, 0, 0, 0)
      @outline = 0.0
    end

    def hash
      [self.class, x, y, radius, color.hash, outline_color.hash, outline].hash
    end

    def outline=(weight)
      @outline = weight

      self
    end

    def color=(value)
      case value
      when Color
        @color = value
      when Array
        @color = Color.new(value[0], value[1], value[2], value[3] || 255)
      end

      self
    end

    def outline_color=(value)
      case value
      when Color
        @outline_color = value
      when Array
        @outline_color = Color.new(value[0], value[1], value[2], value[3] || 255)
      end

      self
    end
  end
end

module Hokusai
  class Commands::Image < Commands::Base
    attr_reader :x, :y, :width, :height, :source

    def initialize(source, x, y, width, height)
      @source = source
      @x = x
      @y = y
      @width = width
      @height = height
    end

    def hash
      [self.class, x, y, width, height, source].hash
    end

    def cache
      [source, width, height].hash
    end
  end

  class Commands::SVG < Commands::Base
    attr_reader :x, :y, :width, :height, :source, :color

    def initialize(source, x, y, width, height)
      @source = source
      @x = x
      @y = y
      @width = width
      @height = height
      @color = Color.new(255, 255, 255, 255)
    end

    def color=(value)
      case value
      when Color
        @color = value
      when Array
        @color = Color.new(value[0], value[1], value[2], value[3] || 255)
      end

      self
    end
  end
end

module Hokusai
  class Commands::Rect < Commands::Base
    attr_reader :x, :y, :width, :height,
                :rounding, :color, :outline,
                :outline_color, :padding, :gradient

    def initialize(x, y, width, height)
      @x = x.to_f
      @y = y.to_f
      @width = width.to_f
      @height = height.to_f
      @outline = Outline.default
      @rounding = 0.0
      @color = Color.new(255, 255, 255, 0)
      @outline_color = Color.new(0, 0, 0, 0)
      @padding = Padding.new(0.0, 0.0, 0.0, 0.0)
      @gradient = nil
    end

    def hash
      [self.class, x, y, width, height, rounding, color.hash, outline.hash, outline_color.hash, padding.hash].hash
    end

    # Modifies the parameter *Canvas*
    # to offset the boundary with
    # this rectangle's computed geometry
    def trim_canvas(canvas)
      x, y, w, h = background_boundary

      canvas.x = x + padding.left + outline.left
      canvas.y = y + padding.top + outline.top
      canvas.width = w - (padding.left + padding.right + outline.left + outline.right)
      canvas.height = h - (padding.top + padding.bottom + outline.top + outline.bottom)

      canvas
    end

    # Shorthand for #width
    def w
      width
    end

    # Shorthand for #height
    def h
      height
    end

    def gradient=(colors)
      unless colors.is_a?(Array) && colors.size == 4 && colors.all? { |color| color.is_a?(Hokusai::Color) }
        raise Hokusai::Error.new("Gradient must be an array of 4 Hokuai::Color")
      end

      @gradient = colors
    end

    # Sets padding for the rectangle
    # `value` is an array with padding declarations
    # at [top, right, bottom, left]
    def padding=(value)
      case value
      when Padding
        @padding = value
      else
        @padding = Padding.convert(value)
      end

      self
    end

    # Sets an outline at `weight`
    def outline=(outline)
      @outline = outline

      self
    end

    # Sets the outline color to `value`
    def outline_color=(value)
      case value
      when Color
        @outline_color = value
      when Array
        @outline_color = Color.new(value[0], value[1], value[2], value[3] || 255)
      else
        raise "Basd color"
      end

      self
    end


    # Sets the color of the rectangle
    # from an array of rgba values
    def color=(value)
      case value
      when Color
        @color = value
      when Array
        @color = Color.new(value[0], value[1], value[2], value[3] || 255)
      end

      self
    end

    # Rounding amount for this rect
    def round=(amount)
      @rounding = amount

      self
    end

    # Returns true if the rectangle has any padding
    def padding?
      [padding.t, padding.r, padding.b, padding.l].any? do |p|
        p != 0.0
      end
    end

    # Returns a tuple with the
    # geometric boundary for this rectangle
    def boundary
      [x, y, width, height]
    end

    # Returns a tuple with the
    # computed geometric **inner** boundary for this rectangle
    # with outlines subtracted
    def background_boundary
      nx = x.dup
      ny = y.dup
      nw = width.dup
      nh = height.dup

      if outline.top > 0.0
        ny += outline.top
        nh -= outline.top
      end

      if outline.left > 0.0
        nx += outline.left
        nw -= outline.left
      end

      if outline.bottom > 0.0
        nh -= outline.bottom
      end

      if outline.right > 0.0
        nw -= outline.right
      end

      [nx, ny, nw, nh]
    end

    # Returns true if this rectangle
    # has an outline
    def outline?
      outline.present?
    end

    # Returns true if this rectangle's
    # outline is uniform
    def outline_uniform?
      outline.uniform?
    end
  end
end
module Hokusai
  class Commands::ScissorBegin < Commands::Base
    attr_reader :x, :y, :width, :height

    def initialize(x, y, width, height)
      @x = x
      @y = y
      @width = width
      @height = height
    end

    def hash
      [self.class, x, y, width, height].hash
    end
  end

  class Commands::ScissorEnd < Commands::Base;
    def hash
      [self.class].hash
    end
  end
end
module Hokusai
  class Commands::Text < Commands::Base
    attr_reader :x, :y, :size, :color,
                :padding, :wrap, :content,
                :font, :static, :line_height,
                :bold, :italic

    def initialize(content, x, y)
      @content = content
      @x = x.to_f
      @y = y.to_f
      @color = Color.new(0, 0, 0, 255)
      @padding = Padding.new(0.0, 0.0, 0.0, 0.0)
      @size = 17
      @wrap = false
      @font = nil
      @static = true
      @bold = false
      @italic = false
      @line_height = 0.0
    end

    def hash
      [self.class, content, color.hash, padding.hash, size, font, wrap].hash
    end

    def bold=(value)
      @bold = value
    end

    def italic=(value)
      @italic = value
    end

    def static=(value)
      @static = !!value
    end

    def line_height=(value)
      @line_height = value
    end

    def dynamic=(value)
      @static = !value
    end

    def font=(value)
      @font = value
    end

    def content=(value)
      @content = value
    end

    def size=(height)
      @size = height.to_f
    end

    # Sets padding for the text
    # `value` is an array with padding declarations
    # at [top, right, bottom, left]
    def padding=(value)
      case value
      when Array
        @padding = Padding.new(value[0], value[1], value[2], value[3])
      when Integer
        @padding = Padding.new(value, value, value, value)
      when Padding
        @padding = value
      end

      self
    end

    # Sets the color of the text
    # from an array of rgba values
    def color=(value)
      case value
      when Color
        @color = value
      when Array
        @color = Color.new(value[0], value[1], value[2], value[3] || 255)
      end
    end

    def padding?
      [padding.t, padding.r, padding.b, padding.l].any? do |p|
        p != 0.0
      end
    end
  end
end
module Hokusai
  class Commands::ShaderBegin < Commands::Base
    attr_reader :vertex_shader, :fragment_shader, :uniforms

    def initialize
      @uniforms = []
      @vertex_shader =  nil
      @fragment_shader = nil
    end

    def vertex_shader=(content)
      @vertex_shader = content
    end

    def fragment_shader=(content)
      @fragment_shader = content
    end

    def uniforms=(values)
      @uniforms = values
    end

    def hash
      [self.class, vertex_shader, fragment_shader].hash
    end
  end

  class Commands::ShaderEnd < Commands::Base
    def hash
      [self.class].hash
    end
  end
end
module Hokusai
  class Commands::Texture < Commands::Base
    attr_reader :x, :y, :width, :height, :rotation, :scale

    def initialize(x, y, width, height)
      @x = x
      @y = y
      @width = width
      @height = height
      @rotation = 0.0
      @scale = 10.0
    end

    def rotation=(value)
      @rotation = value
    end

    def scale=(value)
      @scale = value
    end

    def hash
      [self.class, x, y, width, height].hash
    end
  end
end
module Hokusai
  class Commands::RotationBegin < Commands::Base
    attr_reader :x, :y, :degrees

    def initialize(x, y, deg)
      @x = x
      @y = y
      @degrees = deg
    end

    def hash
      [self.class, x, y, degrees].hash
    end
  end

  class Commands::RotationEnd < Commands::Base;
    def hash
      [self.class].hash
    end
  end
end
module Hokusai
  class Commands::ScaleBegin < Commands::Base
    attr_reader :x, :y

    def initialize(x, y = x)
      @x = x
      @y = y
    end

    def hash
      [self.class, x, y].hash
    end
  end

  class Commands::ScaleEnd < Commands::Base;
    def hash
      [self.class].hash
    end
  end
end
module Hokusai
  class Commands::TranslationBegin < Commands::Base
    attr_reader :x, :y

    def initialize(x, y = x)
      @x = x
      @y = y
    end

    def hash
      [self.class, x, y].hash
    end
  end

  class Commands::TranslationEnd < Commands::Base;
    def hash
      [self.class].hash
    end
  end
end

module Hokusai
  # A proxy class for invoking various UI commands
  #
  # Invocations of commands are immediately sent to the backend
  # for drawing
  #
  # Used as part of the drawing api for Hokusai::Block
  class Commands
    attr_reader :queue

    def initialize
      @queue = []
    end

    # Draw a rectangle
    #
    # @param [Float] the x coordinate
    # @param [Float] the y coordinate
    # @param [Float] the width of the rectangle
    # @param [Float] height of the rectangle
    def rect(x, y, w, h)
      command = Commands::Rect.new(x, y, w, h)

      yield(command)

      queue << command
    end

    # Draw a circle
    #
    # @param [Float] x coordinate
    # @param [Float] y coordinate
    # @param [Float] radius of the circle
    def circle(x, y, radius)
      command = Commands::Circle.new(x, y, radius)

      yield(command)

      queue << command
    end

    # Draws an SVG
    #
    # @param [String] location of the svg
    # @param [Float] x coord
    # @param [Float] y coord
    # @param [Float] width of the svg
    # @param [Float] height of the svg
    def svg(source, x, y, w, h)
      command = Commands::SVG.new(source, x, y, w, h)

      yield(command)

      queue << command
    end

    # Invokes an image command
    # from a filename, at position {x,y} with `w`x`h` dimensions
    def image(source, x, y, w, h)
      queue << Commands::Image.new(source, x, y, w, h)
    end

    # Invokes a scissor begin command
    # at position {x,y} with `w`x`h` dimensions
    def scissor_begin(x, y, w, h)
      queue << Commands::ScissorBegin.new(x, y, w, h)
    end

    # Invokes a scissor stop command
    def scissor_end
      queue << Commands::ScissorEnd.new
    end

    def shader_begin
      command = Commands::ShaderBegin.new

      yield command

      queue << command
    end

    def shader_end
      queue << Commands::ShaderEnd.new
    end

    def rotation_begin(x, y, deg)
      queue << Commands::RotationBegin.new(x, y, deg)
    end

    def rotation_end
      queue << Commands::RotationEnd.new
    end

    def scale_begin(*args)
      queue << Commands::ScaleBegin.new(*args)
    end

    def scale_end
      queue << Commands::ScaleEnd.new
    end

    def translation_Begin(x, y)
      queue << Commands::TranslationBegin.new
    end

    def translation_end
      queue << Commands::TranslationEnd.new
    end

    def texture(x, y, w, h)
      command = Commands::Texture.new(x, y, w, h)

      yield command

      queue << command
    end

    # Draws text
    #
    # @param [String] the text content
    # @param [Float] x coord
    # @param [Float] y coord
    def text(content, x, y)
      command = Commands::Text.new(content, x, y)
      yield command

      queue << command
    end

    def execute
      queue.each(&:draw)
    end

    def clear!
      queue.clear
    end
  end
end
module Hokusai
  # A Backend agnostic font interface
  #
  # Backends are expected to implement the following methods
  class Font
    # Creates a wrapping of text based on container width and font size
    #
    # @param [String] the text to wrap
    # @param [Integer] the font size
    # @param [Float] the width of the container
    # @param [Float] an initital offset
    # @return [Hokusai::Clamping]
    def clamp(text, size, width, initial_offset = 0.0)
      raise Hokusai::Error.new("Font #clamp not implemented")
    end

    # Creates a wrapping of text based on the container width and font size
    # and parses markdown
    # @param [String] the text to wrap
    # @param [Integer] the font size
    # @param [Float] the width of the container
    # @param [Float] an initital offset
    # @return [Hokusai::Clamping]
    def clamp_markdown(text, size, width, initial_offset = 0.0)
      raise Hokusai::Error.new("Font #clamp not implemented")
    end

    # @return [Integer] the font height
    def height
      raise Hokusai::Error.new("Font #height not implemented")
    end
  end

  # A class representing wrapped text
  #
  # A clamping has many segments, delimited by a newline
  # A segment has many possible groups, and a group has many possible charss
  class Clamping
    class Char
      attr_reader :raw

      def initialize(raw)
        @raw = raw
      end

      # @return [Float] the width of the char
      def width
        raw[:width]
      end

      # @return [Integer] the offset of the char relative to the clamping
      def offset
        raw[:offset]
      end
    end

    class Group
      attr_reader :raw

      def initialize(raw)
        @raw = raw
      end

      # @return [Integer] the offset of the group relative to the clamping 
      def offset
        @offset ||= raw[:offset]
      end

      # @return [Integer] number of chars in this group
      def size
        @size ||= raw[:size]
      end

      # @return [Float] the total width of chars in this group
      def width
        chars.sum(&:width)
      end

      # @return [UInt] a flag for this group type
      def type
        @type ||= raw[:type]
      end

      # @return [Bool] is this group normal?
      def normal?
        @normal ||= type == LibHokusai::GROUP_NORMAL
      end

      # @return [Bool] is this group bold?
      def bold?
        @bold ||= ((type & LibHokusai::GROUP_BOLD) != 0)
      end

      # @return [Bool] is this group italics?
      def italics?
        @italics ||= ((type & LibHokusai::GROUP_ITALICS) != 0)
      end

      # @return [Bool] does this group represent a hyperlink?
      def link?
        @link ||= ((type & LibHokusai::GROUP_LINK) != 0)
      end

      # @return [Bool] does this group represent a code block?
      def code?
        @code ||= type & LibHokusai::GROUP_CODE
      end

      # @return [String] the hyperlink for this group if there is one
      def link
        @href ||= raw[:payload].read_string
      end

      # @return [Array<Hokusai::Char>] an array of chars
      def chars
        return @chars unless @chars.nil?

        @chars = []
        each_char do |char|
          @chars << char
        end

        @chars
      end

      def each_char
        char = raw[:chars]
        i = 0

        while !char.null?
          yield Char.new(char), i
          i += 1
          char = char[:next_char]
        end
      end 
    end

    class Segment
      attr_reader :raw

      def initialize(raw)
        @raw = raw
      end

      # A segment width given a range of offsets
      # NOTE: Defaults to the full segment
      def width(range = (offset...offset + size))
        chars[range]&.sum(&:width) || 0.0
      end

      # @return [Integer] the offset of this segment relative to the clamping
      def offset
        raw[:offset]
      end

      # @return [Integer] the number of chars in this segment
      def size
        raw[:size]
      end

      # @return [Array<Hokusai::Char>] an array of chars
      def chars
        return @chars unless @chars.nil?

        @chars = []
        each_char do |char|
          @chars << char
        end

        @chars
      end

      def each_char
        char = raw[:chars]
        i = 0

        while !char.null?
          yield Char.new(char), i
          i += 1
          char = char[:next_char]
        end
      end

      # @return [Array<Hokusai::Group>] an array of clamping groups
      def groups
        return @groups unless @groups.nil?

        @groups = []
        each_group do |group|
          @groups << group
        end

        @groups
      end

      def each_group
        group = raw[:groups]
        i = 0
        until group.null?
          yield Group.new(group), i
          i.succ
          group = group[:next_group]
        end
      end

      def select_end
        raw[:select_end]
      end

      def select_begin
        raw[:select_begin]
      end

      def select_begin=(val)
        raw[:select_begin] = val
      end

      def select_end=(val)
        raw[:select_end] = val.nil? ? select_begin : val
      end

      def has_selection?
        !select_end.nil? && !select_begin.nil?
      end

      def char_is_selected(char)
        return false if select_begin.nil? || select_end.nil? || (select_end - select_begin).zero?

        (select_begin..select_end).include?(char.offset)
      end

      def make_selection(start, stop)
        self.select_begin = start
        self.select_end = stop
      end
    end

    attr_reader :raw, :markdown

    def initialize(raw, markdown: false)
      @markdown = markdown
      @raw = raw
    end

    def segments
      return @segments unless @segments.nil?

      @segments = []
      each_segment do |segment|
        @segments << segment
      end

      @segments
    end

    def debug
      LibHokusai.hoku_text_clamp_debug(raw)
    end

    def each_segment
      segment = raw[:segments]
      i = 0

      until segment.null?
        yield Segment.new(segment), i
        i += 1


        segment = segment[:next_segment]
      end
    end

    def text(segment)
      raw[:text][segment.offset, segment.size]
    end

    def [](offset, size)
      raw[:text][offset, size]
    end

    def to_a
      segments.map do |segment|
        text(segment)
      end
    end
  end

  # Keeps track of any loaded fonts
  class FontRegistry
    attr_reader :fonts, :active_font

    def initialize
      @fonts = {}
      @active_font = nil
    end

    # Registers a font
    #
    # @param [String] the name of the font
    # @param [Hokusai::Font] a font
    def register(name, font)
      raise Hokusai::Error.new("Font #{name} already registered") if fonts[name]

      fonts[name] = font
    end

    # Returns the active font's name
    #
    # @return [String]
    def active_font_name
      raise Hokusai::Error.new("No active font") if active_font.nil?

      active_font
    end

    # Activates a font by name
    #
    # @param [String] the name of the registered font
    def activate(name)
      raise Hokusai::Error.new("Font #{name} is not registered") unless fonts[name]

      @active_font = name
    end

    # Fetches a font
    #
    # @param [String] the name of the registered font
    # @return [Hokusai::Font]
    def get(name)
      fonts[name]
    end

    # Fetches the active font
    #
    # @return [Hokusai::Font]
    def active
      fonts[active_font]
    end
  end
end
# frozen_string_literal: true

module Hokusai
  # A Basic UI Event
  class Event
    attr_reader :captures
    attr_accessor :stopped

    # Sets the name of this event kind
    def self.name(name)
      @name = name
    end

    def name
      self.class.instance_variable_get("@name")
    end

    def add_evented_styles(block)
      if target = block.node.meta.target
        block.node.add_evented_styles(target.class, name)
      end
    end

    def add_capture(block)
      captures << block
    end

    # Has the event stopped propagation?
    # @return [Bool]
    def stopped
      @stopped ||= false
    end

    # Stop propagation on this event
    # @return [Void]
    def stop
      self.stopped = true
    end

    # @return [Array<Block>] the captured blocks for this event
    def captures
      @captures ||= []
    end

    # A JSON string representing this event
    # 
    # Used in automation
    # @return [String]
    def to_json
      raise Hokusai::Error.new("#{self.class} must implement to_json")
    end

    # Does the event match the provided Hokusai::Block?
    #
    # @param [Hokusai::Block]
    # @return [Bool]
    def matches(block)
      return false if block.node.portal.nil?

      val = block.node.portal.ast.event(name)

      !!val
    end

    # Emit the event to all captured blocks,
    # stopping if any of the blocks stop propagation
    def bubble
      while block = captures.pop
        block.emit(name, self)
        break if stopped
      end
    end
  end
end

# frozen_string_literal: true

module Hokusai
  class KeyboardEvent < Event
    attr_reader :input

    def initialize(input, state)
      @input = input
      @state = state
      @keyboard = input.keyboard
    end

    def printable?
      @keyboard.printable?
    end
    
    def pressed
      @keyboard.pressed
    end

    def released
      @keyboard.released
    end

    def char
      @keyboard.char
    end
    
    def symbol
      @keyboard.symbol
    end

    def code
      @keyboard.code
    end

    def shift
      @keyboard.shift
    end

    def super
      @keyboard.send(:super)
    end

    def ctrl
      @keyboard.ctrl
    end

    def alt
      @keyboard.alt
    end

    def hovered(canvas)
      input.hovered?(canvas)
    end

    def to_json
      {
        keypress: {
          keycode: code,
          char: char.to_s,
          super: self.super,
          control: ctrl,
          shift: shift,
          alt: alt
        }
      }.to_json
    end
  end

  class KeyUpEvent < KeyboardEvent
    name "keyup"

    def key
      released[0]&.[](:symbol)
    end

    def code
      released[0]&.[](:code)
    end

    def char
      released[0]&.[](:char)
    end

    def capture(block, canvas)
      add_capture(block) if matches(block) && released.size > 0
    end
  end

  class KeyPressEvent < KeyboardEvent
    name "keypress"

    def key
      pressed[0]&.[](:symbol)
    end

    def code
      pressed[0]&.[](:code)
    end

    def char
      pressed[0]&.[](:char)
    end

    def capture(block, _)
      return unless matches(block) && pressed.size > 0
      add_capture(block)
    end
  end
end
# frozen_string_literal: true

module Hokusai
  class MouseEvent < Event
    attr_reader :input, :state

    def initialize(input, state)
      @input = input
      @mouse = input.mouse
      @left = @mouse.left
      @right = @mouse.right
      @middle = @mouse.middle
      @state = state
    end

    def mouse
      @mouse
    end

    def pos
      mouse.pos
    end

    def delta
      mouse.delta
    end

    def scroll
      mouse.scroll
    end

    def scroll_delta
      mouse.scroll_delta
    end

    def left
      @left
    end

    def right
      @right
    end

    def middle
      @middle
    end

    def to_json
      hash = {}
      hash[:pos] = { x: pos.x, y: pos.y }

      [:left, :right, :middle].each do |button|
        hash[button] = {
          down: send(button).down,
          up: send(button).up,
          clicked: send(button).clicked,
          released: send(button).released
        }
      end

      hash[:scroll] = scroll
      hash[:scroll_delta] = scroll_delta

      hash.to_json
    end

    protected

    def hovered(canvas)
      input.hovered?(canvas)
    end
  end

  class MouseMoveEvent < MouseEvent
    name "mousemove"

    def capture(block, canvas)
      add_evented_styles(block) if hovered(canvas)

      if matches(block) #&& (delta.y != 0.0000000000 && delta.x != 0.0000000000)
        add_capture(block)
      end
    end
  end

  class ClickEvent < MouseEvent
    name "click"

    def capture(block, canvas)
      if left.clicked && clicked(canvas)
        block.node.meta.focus

        add_evented_styles(block) if hovered(canvas)

        if matches(block)
          add_capture(block)
        end
      elsif left.clicked
        block.node.meta.blur
      end
    end

    def clicked(canvas)
      left.clicked && input.hovered?(canvas)
    end
  end

  class MouseUpEvent < MouseEvent
    name "mouseup"

    def capture(block, canvas)
      add_evented_styles(block) if left.up && hovered(canvas)

      if left.up && matches(block)
        add_capture(block)
      end
    end
  end

  class MouseDownEvent < MouseEvent
    name "mousedown"

    def capture(block, canvas)
      add_evented_styles(block) if left.down && hovered(canvas)

      if left.down && matches(block)
        add_capture(block)
      end
    end
  end

  class WheelEvent < MouseEvent
    name "wheel"

    def capture(block, canvas)
      add_evented_styles(block) if scroll_delta != 0.0

      if matches(block) && scroll_delta != 0.0
        add_capture(block)
      end
    end
  end

  class HoverEvent < MouseEvent
    name "hover"

    def capture(block, canvas)
      add_evented_styles(block) if hovered(canvas)

      add_capture(block)
    end

    def bubble
      while block = captures.pop
        block.emit(name, self)

        cursor = block.node.meta.get_prop(:cursor)&.to_sym

        if !state.set && cursor == :manual
          state.set = true
        end

        if !state.set && cursor && cursor != :manual
          Hokusai.set_mouse_cursor(cursor)
          state.set = true
        end

        break if stopped
      end

      if !state.nil? && !state.set
        Hokusai.set_mouse_cursor(:default)
      end
    end
  end

  class MouseOutEvent < MouseEvent
    name "mouseout"

    def capture(block, canvas)
      add_capture(block) if matches(block)

      if left.clicked && !clicked(canvas)
        block.node.meta.blur
      end
    end

    def clicked(canvas)
      left.clicked && input.hovered?(canvas)
    end
  end
end

# frozen_string_literal: true

module Hokusai
  class TouchEvent < Event
    attr_reader :input

    def initialize(input, state)
      @input = input
      @state = state
      @touch = input.touch
    end

    def tapped?
      @touch.tapped?
    end

    def swiped?
      @touch.swiped?
    end
    
    def longtapped?
      @touch.longtapped?
    end

    def longtapping?
      @touch.longtapping?
    end

    def touching?
      @touch.touching?
    end

    def duration
      @touch.duration
    end

    def direction
      @touch.direction
    end

    def distance
      @touch.distance
    end

    def angle
      @touch.angle
    end

    def position
      @touch.position
    end

    def last_position
      @touch.last_position
    end

    def touch_len
      @touch.touch_len
    end

    def touch_count
      @touch.touch_count
    end

    def timer
      @touch.timer
    end

    def hovered(canvas)
      input.hovered?(canvas)
    end

    def to_json
      {
        keypress: {
          hold: hold,
          hold_duration: hold_duration.to_s,
        }
      }.to_json
    end
  end

  class TapHoldEvent < TouchEvent
    name "taphold"

    def capture(block, canvas)
      if matches(block) && longtapped? && hovered(canvas) 
        captures << block
      end
    end
  end

  class PinchEvent < TouchEvent
    name "pinch"

    def capture(block, canvas)
      if false && matches(block)
        captures << block
      end
    end
  end

  class SwipeEvent < TouchEvent
    name "swipe"

    def capture(block, canvas)
      if swiped? && matches(block)
        captures << block
      end
    end
  end
end
module Hokusai
  class PainterEntry
    attr_reader :block, :parent, :x, :y, :w, :h
    def initialize(block, x, y, w, h)
      @block = block
      @x = x
      @y = y
      @w = w
      @h = h
    end
  end

  class CursorState
    attr_accessor :set

    def initialize
      @set = false
    end
  end

  ZTARGET_ROOT = "root"
  ZTARGET_PARENT = "parent"

  class Painter
    attr_reader :root, :input, :before_render, :after_render,
                :events

    def initialize(root, input)
      state = CursorState.new

      @root = root
      @input = input
      @events = {
        hover: HoverEvent.new(input, state),
        wheel: WheelEvent.new(input, state),
        click: ClickEvent.new(input, state),
        mousemove: MouseMoveEvent.new(input, state),
        mouseout: MouseOutEvent.new(input, state),
        mouseup: MouseUpEvent.new(input, state),
        mousedown: MouseDownEvent.new(input, state),
        keyup: KeyUpEvent.new(input, state),
        keypress: KeyPressEvent.new(input, state)
      }

      add_touch_events(events, input, state) unless input.touch.nil?
    end

    def add_touch_events(events, input, state)
      events.merge!({
        taphold: TapHoldEvent.new(input, state),
        pinch: PinchEvent.new(input, state),
        swipe: SwipeEvent.new(input, state),
      })
    end

    def on_before_render(&block)
      @before_render = block
    end

    def on_after_render(&block)
      @after_render = block
    end

    # def debug(parent, children)
    #   @i ||= 0
      
    #   pp [
    #     "#{@i}",
    #     "parent: #{parent.block.class}##{parent.block.node.portal&.ast&.id} (z: #{parent.block.node.meta.get_prop(:z)})",
    #     "children: #{children.map {|c| "#{c.block.class}##{c.block.node.portal&.ast&.id} (z: #{c.block.node.meta.get_prop(:z)})"} }"
    #   ]
    #   @i += 1
    # end

    # @return [Array(Commands::Base)] the command list
    def render(canvas, resize = false, capture: true)
      return if root.children.empty?

      zindexed = {}
      zindex_counter = 0

      zroot_x = canvas.x
      zroot_y = canvas.y
      zroot_w = canvas.width
      zroot_h = canvas.height

      @root.on_resize(canvas) if resize

      before_render&.call([root, nil], canvas, input)

      root_children = (canvas.reverse? ? root.children?&.reverse.dup : root.children?&.dup) || []
      groups = []
      root_entry = PainterEntry.new(root, canvas.x, canvas.y, canvas.width, canvas.height)
      groups << [root_entry, measure(root_children, canvas)]

      mouse_y = input.mouse.pos.y
      can_capture = mouse_y >= (canvas.y || 0.0) && mouse_y <= (canvas.y || 0.0) + canvas.height

      hovered = false
      while payload = groups.pop
        group_parent, group_children = payload
        
        parent_z = group_parent.block.node.meta.get_prop(:z)&.to_i
        zindex_counter -= 1 if (parent_z || 0) > 0 && group_children.empty?

        while group = group_children.shift
          z = group.block.node.meta.get_prop(:z)&.to_i || 0
          ztarget = group.block.node.meta.get_prop(:ztarget)

          if (zindex_counter > 0 || z > 0)
            pos = group.block.node.meta.get_prop(:zposition)
            pos = pos.nil? ? Hokusai::Boundary.default : Hokusai::Boundary.convert(pos)

            case ztarget
            when ZTARGET_ROOT
              entry = PainterEntry.new(group.block, (zroot_x || 0.0) + pos.left, (zroot_y || 0.0) + pos.top, zroot_w + pos.right, zroot_h + pos.bottom).freeze
            when ZTARGET_PARENT
              entry = PainterEntry.new(group.block, (group_parent.x || 0.0) + pos.left, (group_parent.y || 0.0) + pos.top, group_parent.w + pos.right, group_parent.h + pos.bottom).freeze
            else
              entry = PainterEntry.new(group.block, group.x + pos.left, group.y + pos.top, group.w + pos.right, group.h + pos.bottom).freeze
            end
          else
            entry = PainterEntry.new(group.block, group.x, group.y, group.w, group.h).freeze
          end


          canvas.reset(entry.x, entry.y, entry.w, entry.h)

          before_render&.call([group.block, group.parent], canvas, input)

          # defer capture for zindexed items so they can stop propagation.
          if capture && (zindex_counter.zero? && z.zero?)
            capture_events(group.block, canvas, hovered: hovered)
          # since evented styles happens during capture and z-index skips capture, well add some
          elsif capture && input.hovered?(canvas)
            if target = group.block.node.meta.target
              group.block.node.add_evented_styles(target.class, "hover")
            end
          end

          if resize
            group.block.on_resize(canvas)
          end

          breaked = false

          group.block.render(canvas) do |local_canvas|
            local_children = (local_canvas.reverse? ? group.block.children?&.reverse : group.block.children?)

            unless local_children.nil?
              groups << [group_parent, group_children]
              parent = PainterEntry.new(group.block, canvas.x, canvas.y, canvas.width, canvas.height)
              groups << [parent, measure(local_children, local_canvas)]

              breaked = true
            else
              breaked = false
            end
          end
          
          if z > 0
            zindex_counter += 1
            # puts ["start (#{z}) <#{parent_z}> {#{zindex_counter}} #{group.block.class}".colorize(:blue), z, group.block.node.portal&.ast&.id]
            zindexed[zindex_counter] ||= []
            zindexed[zindex_counter] << group
          elsif zindex_counter > 0
            zindexed[zindex_counter] ||= []
            # puts ["push (#{z}) <#{parent_z}>  {#{zindex_counter}} initial #{group.block.class}".colorize(:red), z, group.block.node.portal&.ast&.id]
            zindexed[zindex_counter] << group
          else
            # puts ["draw (#{z}) <#{parent_z}>  {#{zindex_counter}} #{group.block.class}".colorize(:yellow), z, group.block.node.portal&.ast&.id]
            group.block.execute_draw
          end


          break if breaked
        end
      end

      zindexed.sort.each do |z, groups|
        groups.each do |group|
          canvas.reset(group.x, group.y, group.w, group.h)
          capture_events(group.block, canvas)
          group.block.execute_draw
        end
      end

      if capture
        events[:hover].bubble
        events[:wheel].bubble
        events[:click].bubble
        events[:keyup].bubble
        events[:keypress].bubble
        events[:mousemove].bubble
        events[:mouseout].bubble
        events[:mousedown].bubble
        events[:mouseup].bubble

        unless input.touch.nil?
          events[:taphold].bubble
          events[:pinch].bubble
          events[:swipe].bubble
        end
      end

      after_render&.call
    end

    def measure(children, canvas)
      x = canvas.x || 0.0
      y = canvas.y || 0.0
      width = canvas.width
      height = canvas.height
      vertical = canvas.vertical

      count = 0
      wcount = 0
      hcount = 0
      wsum = 0.0
      hsum = 0.0

      children.each do |block|
        z = block.node.meta.get_prop?(:z)&.to_i || 0
        h = block.node.meta.get_prop?(:height)&.to_f
        w = block.node.meta.get_prop?(:width)&.to_f

        next if z > 0

        if w
          wsum += w
          wcount = wcount.succ
        end

        if h
          hsum += h
          hcount = hcount.succ
        end

        count = count.succ
      end

      neww = width
      newh = height

      if vertical
        c = (count - hcount)
        newh = (newh - hsum)  / (c.zero? ? 1 : c)
      else
        c = (count - wcount)
        neww = (neww - wsum) / (c.zero? ? 1 : c)
      end

      entries = []

      children.each do |block|
        # nw, nh = ntuple
        w = block.node.meta.get_prop?(:width)&.to_f || neww
        h = block.node.meta.get_prop?(:height)&.to_f || newh

        # local_canvas = Hokusai::Canvas.new(w, h, x, y)
        # block.node.meta.props[:height] ||= h
        # block.node.meta.props[:width] ||= w

        entries << PainterEntry.new(block, x, y, w, h).freeze

        if vertical
          y += h
        else
          x += w
        end
      end

      entries
    end

    def capture_events(block, canvas, hovered: false)
      if block.node.portal.nil?
        return
      end

      if input.hovered?(canvas)
        events[:hover].capture(block, canvas)
        events[:click].capture(block, canvas)
        events[:wheel].capture(block, canvas)
        events[:mouseup].capture(block, canvas)
        events[:mousedown].capture(block, canvas)
      else
        events[:mouseout].capture(block, canvas)
      end
      events[:mousemove].capture(block, canvas)

      if input.hovered?(canvas) || block.node.meta.focused || input.keyboard_override
        events[:keyup].capture(block, canvas)
        events[:keypress].capture(block, canvas)
      end

      unless input.touch.nil?
        events[:taphold].capture(block, canvas)
        events[:pinch].capture(block, canvas)
        events[:swipe].capture(block, canvas)
      end
    end
  end
end

module Hokusai::Util
  class GeometrySelection
    attr_accessor :start_x, :start_y, :stop_x, :stop_y,
                  :type, :cursor, :diff, :click_pos, :parent

    def initialize(parent)
      @parent = parent
      @type = :none         # state for the geometry selection (active/frozen/etc)
      @start_x = 0.0        # the x coordinate for the geometry
      @stary_y = 0.0        # the y coordinate for the geometry 
      @stop_x = 0.0
      @stop_y = 0.0
      @diff = 0.0
      @cursor = nil
      @click_pos = nil
    end

    def set_click_pos(x, y)
      @click_pos = [x, y]
    end

    def none?
      type == :none
    end

    def ready?
      type == :none || type == :frozen
    end

    def clear
      self.start_x = 0.0
      self.start_y = 0.0
      self.stop_x = 0.0
      self.stop_y = 0.0
      self.cursor = nil
    end

    def changed_direction?
      @changed_direction
    end

    def active?
      type == :active
    end

    def frozen?
      type == :frozen
    end

    def activate!
      self.type = :active
    end

    def freeze!
      self.type = :frozen
    end

    def coords
      [start_x, stop_x, start_y, stop_y]
    end

    def start(x, y)
      self.start_x = x
      self.start_y = y
      self.stop_x = x
      self.stop_y = y
      self.cursor = nil

      activate!
    end

    def stop(x, y)
      self.stop_x = x
      self.stop_y = y

      if up? && @direction == :down || down? && @direction == :up
        @changed_direction = true
      else
        @changed_direction = false
      end

      @direction = up? ? :up : :down
    end

    def up?(height = 0)
      stop_y < start_y - height
    end

    def down?(height = 0)
      start_y <= stop_y - height
    end

    def left?
      stop_x < start_x
    end

    def right?
      start_x <= stop_x
    end

    def cursor
      return nil unless @cursor

      return [@cursor[0], @cursor[1] - parent.offset_y, @cursor[2], @cursor[3]] if frozen?

      @cursor
    end

    def rect_selected(rect)
      selected(rect[0], rect[1], rect[2], rect[3])
    end

    def clicked(x,y,w,h)
      return false if click_pos.nil?

      pos = Hokusai::Rect.new(x, y, w, h)
      # pos.move_x_left
      pos.includes_x?(click_pos[0]) && pos.includes_y?(click_pos[1])
    end

    def selected(x, y, width, height)
      return false if none?

      if frozen?
        y -= parent.offset_y
      end

      sx = @start_x
      sy = @start_y
      ex = @stop_x
      ey = @stop_y

      down = sy <= ey
      up = ey < sy
      left = ex < sx
      right = sx <= ex

      rect = Hokusai::Rect.new(x, y, width, height)
      x_shifted_right = rect.move_x_right(1)
      y_shifted_up = rect.move_y_up(2)
      y_shifted_down = rect.move_y_down(2)
      end_y = y + height

      a = ((down &&
        # first line of multiline selection
        ((x_shifted_right > sx && end_y < ey && rect.includes_y?(sy)) ||
          # last line of multiline selection
          (x_shifted_right <= ex && y_shifted_up + height < ey && y > sy) ||
          # middle line (all selected)
          (y > sy && end_y < ey))) ||
        (up &&
          # first line of multiline selection
          ((x_shifted_right <= sx && y > ey && rect.includes_y?(sy)) ||
          # last line of multiline selection
            (x_shifted_right >= ex && y_shifted_down > ey && end_y < sy) ||
            # middle line (all selected)
            (y > ey && y + height < sy))) ||
        # single line selection
        ((rect.includes_y?(sy) && rect.includes_y?(ey)) &&
          ((left && x_shifted_right < sx && x_shifted_right > ex) || (right && x_shifted_right > sx && x_shifted_right < ex)))
      )

      a
    end
  end
end
module Hokusai::Util
  class PositionSelection
    attr_accessor :positions, :cursor_index, :direction, :active

    def initialize
      @cursor_index = nil
      @positions = []
      @direction = :right
      @active = false
    end

    def move(to, selecting)
      self.active = selecting
  
      return if cursor_index.nil?

      # puts ["before", to, cursor_index, positions].inspect
      
      case to
      when :right
        self.cursor_index += 1
        if selecting && !positions.empty? && cursor_index <= positions.last
          positions.shift
        elsif selecting
          positions << cursor_index 
        end

      when :left
        if selecting && !positions.empty? && cursor_index >= positions.last
          positions.pop
        elsif selecting
          positions.unshift cursor_index
        end
  
        self.cursor_index -= 1 unless cursor_index == -1
      end
    end

    def active?
      @active
    end

    def left?
      direction == :left
    end

    def right?
      direction == :right
    end

    def clear
      self.cursor_index = nil
      positions.clear
    end

    def selected(index)
      active && (positions.first..positions.last).include?(index)
    end

    def select(range)
      self.positions = range.to_a
    end
  end
end

module Hokusai::Util
  class SelectionNew
    attr_reader :geom, :pos
    attr_accessor :type, :offset_y, :diff, :cursor

    def initialize
      @geom = GeometrySelection.new(self)
      @pos = PositionSelection.new
      @type = :geom
      @offset_y = 0.0
      @diff = 0.0
      @cursor = nil
    end

    def clear
      pos.clear
      geom.clear
    end

    def cursor
      geom.cursor
    end

    def geom!
      pos.clear
      pos.cursor_index = nil

      self.type = :geom
    end

    def pos!
      geom.clear

      self.type = :pos
    end

    def geom?
      type == :geom
    end

    def pos?
      type == :pos
    end

    def left?
      geom? ? geom.left? : pos.left?
    end

    def right?
      geom? ? geom.right? : pos.right?
    end

    def up?
      geom? && geom.up?
    end

    def down?
      geom? && geom.down?
    end

    def selecting?
      !(geom.type == :none && geom.click_pos.nil?)
    end

    # should we show the cursor?
    def active?
      !cursor.nil?
    end
  end
end
module Hokusai::Util
  class PieceTable
    attr_accessor :buffer, :buffer_add, :last_piece_index
    attr_reader :pieces

    def initialize(buffer = "")
      @pieces = [[:original, 0, buffer.size]]
      @buffer_add = ""
      @buffer = buffer
      @last_piece_index = nil
    end

    def to_s
      io = ""
      pieces.each do |(which, start, size)|
        case which
        when :original
          io << buffer[start, size]
        else
          if buffer_add[start, size].nil?
            raise Hokusai::Error.new("#{which} Bad: #{start} #{size}")
          end

          io << buffer_add[start, size]
        end
      end

      io
    end

    def insert(text, offset = buffer.size - 1)
      return nil if text.size.zero?

      piece_at_buffer_offset(offset) do |(piece, index, remainder)|
        which, start, size = piece
        length = remainder - start
        
        new_pieces = []
        new_pieces << [which, start, length] if length > 0
        new_pieces << [:add, buffer_add.size, text.size]
        new_pieces << [which, length + start, size - length] if size - length > 0
  
        self.last_piece_index = index + 1
        self.pieces[index..index] = new_pieces
        self.buffer_add += text
      end
    end

    def delete(offset, count)
      piece_at_buffer_offset(offset) do |(piece_left, index_left, remainder_left)|
        piece_at_buffer_offset(offset + count) do |(piece_right, index_right, remainder_right)|
          if index_left == index_right
            if remainder_left == piece_left[1]
              pieces[index_left] = [piece_left[0], piece_left[1] + count, piece_left[2] - count]

              return
            elsif remainder_right == piece_left[1] + piece_left[2]
              pieces[index_left] = [piece_left[0], piece_left[1], piece_left[2] - count]
              
              return
            end
          end
  
          new_pieces = []
          left = [piece_left[0], piece_left[1], remainder_left - piece_left[1]]
          left_condition = (remainder_left - piece_left[1] > 0)
          right = [piece_right[0], remainder_right, piece_right[2] - (remainder_right - piece_right[1])]
          right_condition =  (piece_right[2] - (remainder_right - piece_right[1]) > 0)

          if !left_condition && !right_condition
            new_pieces << left
          end
          
          if left_condition
            new_pieces << left
          end

          if right_condition
            new_pieces << right
          end

          self.pieces[index_left..index_right] = new_pieces
          self.last_piece_index = nil
        end
      end
    end

    private def piece_at_buffer_offset(offset)
      raise Hokusai::Error.new("Piece table offset is negative") if offset.negative?
  
      remainder = offset
  
      pieces.each_with_index do |piece, index|
        if remainder <= piece[2]
          yield([piece, index, remainder + piece[1]])
          
          return
        end
  
        remainder -= piece[2]
      end      

      raise Hokusai::Error.new("Piece table offset is greater than the buffer! #{offset}\n#{pieces}")
    end
  end
end

module Hokusai::Util
  class Wrapped
    attr_accessor :y
    attr_accessor :text, :x, :width, :height, :extra, :widths, :positions
    
    def initialize(text, rect, extra, widths:, positions:)
      @text = text
      @x = rect.x
      @y = rect.y
      @width = rect.width
      @height = rect.height
      @widths = widths
      @extra = extra
      @positions = positions
    end

    def range
      positions.first..positions.last
    end
  end

  class WrapCachePayload
    attr_accessor :copy, :positions, :cursor
    
    def initialize(copy, positions, cursor)
      @copy = copy
      @positions = positions
      @cursor = cursor
    end
  end

  # A cache that stores the results of WrapStream.
  # Utiltiy methods are provided to quickly fetch a subset of tokens
  # Based on a given window's coordinates (canvas)
  class WrapCache
    attr_accessor :tokens

    # returns range denoting the index of the changed lines
    # from 2 different strings.
    # NOTE: the change must be consecutive
    def self.diff(first, second)
      arr = (0..first.length).to_a

      v = arr.bsearch do |i|
        first.rindex(second[0..i]) != 0
      end

      # bounds checks
      v = first.size if v.nil?
      v -= 1 if first[v] == "\n"

      a = 0
      while true
        if first[v] == "\n"
          a = v + 1
          break
        elsif v.zero?
          a = v
          break
        end
        v -= 1
      end

      b = a
      while true
        if first[b].nil?
          b = first.size - 1
          break
        elsif first[b] == "\n"
          break
        end
        b += 1
      end

      a..b
    end

    def initialize
      @tokens = []
    end

    def <<(element)
      @tokens << element
    end

    def splice(stream, last_content, new_content, selection: nil)
      change_line_indicies = WrapCache.diff(last_content, new_content)
      new_changed_line_indicies = WrapCache.diff(new_content, last_content)

      new_data = new_content[new_changed_line_indicies]
      old_text_callback = stream.on_text_cb
      records = []
      # the height of the new records
      records_height = 0.0

      stream.on_text do |wrapped|
        unless wrapped.positions.empty?
          records_height += wrapped.height
          wrapped.positions.map! do |pos|
            pos + change_line_indicies.begin
          end
          records << wrapped
        end
      end

      stream.wrap(new_data, nil)
      stream.flush

      # puts ["original.tokens.last.y", tokens.last.y].inspect

      # splice in new tokens
      #
      # update the new positions
      # NOTE: still need to udpate the y positions with the 
      # records.each do |record|
      #   records_height += record.height
      #   record.positions.map! do |pos|
      #     pos + change_line_indicies.begin
      #   end
      # end

      diff_pos = (new_changed_line_indicies.end - change_line_indicies.end)
      new_tokens = []
      found = false
      last_token = nil
      new_last_tokens_height = 0.0
      last_tokens_height = 0.0
      insert_index = 0

      while token = tokens.shift
        next if token.positions.empty?
        if token.range.begin >= change_line_indicies.begin && token.range.end <= change_line_indicies.end
          # this is a match
          # we want to remove these tokens from the list...and then sub in our new tokens.
          last_token = token
          last_tokens_height += token.height
          found = true
          next
        end

        if found
          token.y += (records_height - last_tokens_height)

          token.positions.map! do |pos|
            pos + diff_pos
          end
        else
          insert_index += 1
          new_last_tokens_height += token.height
        end

        new_tokens << token
      end

      records.each do |record|
        record.y += new_last_tokens_height
      end

      # puts ["insert", records.first.y, records.map(&:height).sum, insert_index, new_last_tokens_height].inspect

      new_tokens.insert(insert_index, *records)
      self.tokens = new_tokens
      

      # i = 0
      # tokens.each do |token|
      #   # puts ["token", token].inspect
      #   token.positions.each do |n|
      #     if n != i
      #       puts ["Mismatch token", token, i, n].inspect
      #     end

      #     i += 1
      #   end
      # end

      # restore callback
      stream.on_text(&old_text_callback)
      # return y
      tokens.last.y + tokens.last.height
    end

    def bsearch(canvas)
      low = 0
      high = tokens.size - 1

      while low <= high
        mid = low + (high - low) / 2

        if matches(tokens[mid], canvas)
          return mid
        end

        if tokens[mid].y > canvas.y
          high = mid - 1
        end

        if tokens[mid].y < canvas.y
          low = mid + 1
        end
      end

      return nil
    end

    def matches(wrapped, canvas)
      wrapped.y >= canvas.y && wrapped.y <= canvas.y + canvas.height
    end

    #  arrows = cursor index
    #  letters = selected positions
    #                          
    #  │     │      │     │     │  
    #  │  A  │   B  │  C  │  D  │  
    #  │     │      │     │     │  
    #  ▼  0  ▼   1  ▼  2  ▼  3  ▼  
    #                           
    #  -1    0      1     2     3  
    #                            
    def selected_area_for_tokens(tokens, selector, copy: false, padding: Hokusai::Padding.default)
      return if selector.nil? || !selector.selecting?

      copy_buffer = ""
      x = nil
      tw = 0.0
      cy = nil
      position_buffer = []
      cursor = nil
      pcursor = nil

      tokens.each do |token|
        tx = token.x + padding.left
        ty = token.y + padding.top

        if token.y != cy
          x = nil
          cy = token.y
          tw = 0.0
        end

        token.widths.each_with_index do |w, i|
          by = selector.geom.frozen? ? ty : ty - selector.offset_y
          sy = ty

          if (selector.geom? && selector.geom.selected(tx, by, w, token.height))
            if (selector.geom.left? || selector.geom.up?)
              cursor ||= [tx, sy, 0.5, token.height]
              pcursor ||= token.positions[i]
            else
              # puts ["set selection cursor: #{sy}"]
              cursor = [tx + w, sy, 0.5, token.height]
              pcursor = token.positions[i]
            end

            position_buffer << token.positions[i]

            if copy
              copy_buffer += token.text[i]
            end

            if x.nil?
              x = tx
            end

            tw += w
          elsif selector.pos? && selector.pos.selected(token.positions[i])
            # puts ["pos 1"]
            if selector.pos.cursor_index == selector.pos.positions.first
              cursor ||= [tx, sy, 0.5, token.height]
              pcursor ||= token.positions[i]
            elsif selector.pos.cursor_index == selector.pos.positions.last
              cursor = [tx + w, sy, 0.5, token.height]
              pcursor = token.positions[i]
            elsif selector.pos.cursor_index + 1 == token.positions[i]
              cursor = [tx, sy, 0.5, token.height]
              pcursor = token.positions[i] - 1
            end

            position_buffer << token.positions[i]

            if copy
              copy_buffer += token.text[i]
            end

            if x.nil?
              x = tx
            end

            tw += w

          # [0, [0]]
          elsif selector.pos? && selector.pos.cursor_index && selector.pos.cursor_index + 1 == token.positions[i]
            # puts "pos 2"
            cursor = [tx, sy, 0.5, token.height]
            pcursor = token.positions[i] - 1
            # position_buffer = selector.pos.positions

            # if copy
            #   copy_buffer += token.text[i]
            # end

          elsif selector.pos? && selector.pos.cursor_index && selector.pos.cursor_index == token.positions[i]
            # puts "pos 3"
            cursor = [tx + w, sy, 0.5, token.height]
            pcursor = selector.pos.cursor_index
            # position_buffer = selector.pos.positions
          elsif selector.geom? && selector.geom.clicked(tx, by, (w / 2), token.height)
            cursor = [tx, sy, 0.5, token.height]
            pcursor = token.positions[i] - 1
            # puts "setting cursor #{sy}"

          elsif selector.geom? && selector.geom.clicked(tx + (w/2.0), by, (w/2.0), token.height)
            # puts "geom click 2"
            cursor = [tx + w, sy, 0.5, token.height]
            pcursor = token.positions[i]
          end
          
          tx += w
        end

        if !x.nil?
          ay = cy + padding.top - selector.offset_y
          yield Hokusai::Rect.new(x, ay, tw, token.height)

          tw = 0.0
        end
      end

      selector.pos.cursor_index = pcursor
      selector.pos.positions = position_buffer
      selector.geom.cursor = cursor

      WrapCachePayload.new(copy_buffer, position_buffer, pcursor)
    end

    def tokens_for(canvas)
      index = bsearch(canvas)
      return [] if index.nil?
      lindex = index.zero? ? index : index - 1
      rindex = index + 1

      while rindex < tokens.size - 1 && matches(tokens[rindex], canvas)
        rindex += 1
      end

      while lindex > 0 && matches(tokens[lindex], canvas)
        lindex -= 1
      end

      tokens[lindex..rindex].clone
    end
  end

  # A disposable streaming text wrapper
  # tokens can be appended onto it, where it they will break on a given width.
  # Opaque payloads can be passed for each token, which will be provided to callbacks.
  # This makes it suitable for processing and wrapping markdown/html/tokenized text
  #
  # height of the wrapped text is tracked with `stream#y`
  class WrapStream
    attr_accessor :buffer, :x, :y, :origin_y, :current_width, :stack, :widths, :current_position, :positions, :on_text_cb
    attr_reader :width, :origin_x, :on_text_cb

    def initialize(width, origin_x = 0.0, origin_y = 0.0, &measure)
      @width = width            # the width of the container for this wrap
      @measure_cb = measure     # a measure callback that returns the width/height of a given char (takes 2 params: a char and an token payload)
      @on_text_cb = ->(_) {}    # a callback that receives a wrapped token for a given line.  (takes a Hokusai::Util::Wrapped paramter)

      @origin_x = origin_x      # the origin x coordinate, x will reset to this
      @x = origin_x             # the marker for x coord, this is used to track against the width of a given line
      @y = origin_y             # the marker for the y coord, this grows by <size> for each line, resulting in the height of the wrapped text
      @current_width = 0.0      # the current width of the buffer
      @stack = []               # a stack storing buffer offsets with their respective token payloads.
      @buffer = ""              # the current buffer that the stack represents.
      
      @current_position = 0     # the current char index
      @positions = []           # a stack of char positions, used for editing
      @widths = []              # a stack of char widths, used later in selection
    end

    NEW_LINE_REGEX = /\n/

    # Appends <text> to the wrap stream.
    # If the text supplies causes the buffer to grow beyond the supplied width
    # The buffer will be flushed to the <on_text_cb> callback.
    #
    # @param [String] text (text to append to this wrap stream)
    # @param [Object] extra (an opaque payload that will be passed to callbacks)
    def wrap(text, extra)
      offset = 0
      size = text.size
      
      # appends the initial stack value for this text
      stack << [((buffer.size)..(text.size + buffer.size - 1)), extra]

      # char-by-char processing.
      while offset < size
        char = text[offset]
        self.current_position = offset

        w, h = measure(char, extra)

        # this char is actually a newline.
        if NEW_LINE_REGEX.match(char)
          self.widths << 0
          self.buffer << char
          self.positions << current_position
          flush

          # append the rest of this text to the stack.
          stack << [(0...(text.size - offset - 1)), extra]
          self.y += h
          self.x = origin_x
          offset += 1

          next
        end

        # adding this char will extend beyond the provided width
        if w + current_width >= width
          # if this is a space in the second half of this line, 
          # split the buffer @ it's index and render
          idx = buffer.rindex(" ")
          if !idx.nil?
            cur = []
            nex = []

            found = false

            # we need to split up the buffer and the ranges.
            while payload = stack.shift
              range, xtra = payload

              # this range contains the space
              # we will split the stack here
              if range.include?(idx)
                cur << [(range.begin..idx), xtra]
                nex << [(0..(range.end - idx - 1)), xtra] unless idx == range.end
              
                found = true
              # the space has not been found
              # append to first stack
              elsif !found
                cur << payload
              # the space has been found
              # append to second stack.
              # (note: we need to subtract the idx from the range because 
              #        we are flushing everything before the space)
              else
                nex << [((range.begin - idx - 1)..(range.end - idx - 1)), xtra] 
              end
            end

            # get the string values from the buffer
            scur = buffer[0..idx]
            snex = buffer[(idx + 1)..-1]

            wcur = widths[0..idx]
            wnex = widths[(idx + 1)..-1]

            pcur = positions[0..idx]
            pnex = positions[(idx + 1)..-1]

            # set the buffer and stack to everything before the space
            self.buffer = scur
            self.widths = wcur
            self.stack = cur
            self.positions = pcur

            flush

            # set the buffer and stack to everything after the space
            self.buffer = snex + char
            self.widths = wnex.concat([w])
            self.positions = pnex.concat([current_position])
            self.stack = nex
            self.x = origin_x
            self.current_width = widths.sum#measure(buffer, xtra).first


            # bump the height
            self.y += h
          # no space: force a break on the char.
          else
            flush

            self.current_width = w
            self.y += h
            self.buffer = text[offset]
            self.widths = [w]
            self.positions = [current_position]
            stack << [(0...(text.size - offset)), xtra]
          end
        # append this char does NOT extend beyond the width
        else
          self.current_width += w
          buffer << char
          widths << w
          positions << current_position
        end

        offset += 1
      end
    end

    # Flushes the current buffer/stack.
    def flush
      stack.each do |(range, extra)|
        content = buffer[range]
        size = content.size
        content_width, content_height = measure(content, extra)

        wrap_and_call(content, content_width, content_height, extra)
        self.x += content_width
      end

      self.buffer = ""
      self.current_width = 0.0
      stack.clear
      widths.clear
      positions.clear
      self.x = origin_x
    end

    def on_text(&block)
      @on_text_cb = block
    end

    private

    def wrap_and_call(text, width, height, extra)
      rect = Hokusai::Rect.new(x, y, width, height)
      @on_text_cb.call Wrapped.new(text.dup, rect, extra, widths: widths.dup, positions: positions.dup)
    end

    def measure(string, extra)
      @measure_cb.call(string, extra)
    end
  end
end

HP_FLAG_VSYNC_HINT = 64                  # Set to try enabling V-Sync on GPU
HP_FLAG_FULLSCREEN_MODE = 2              # Set to run program in fullscreen
HP_FLAG_WINDOW_RESIZABLE = 4             # Set to allow resizable window
HP_FLAG_WINDOW_UNDECORATED = 8           # Set to disable window decoration (frame and buttons)
HP_FLAG_WINDOW_HIDDEN = 128              # Set to hide window
HP_FLAG_WINDOW_MINIMIZED = 512           # Set to minimize window (iconify)
HP_FLAG_WINDOW_MAXIMIZED = 1024          # Set to maximize window (expanded to monitor)
HP_FLAG_WINDOW_UNFOCUSED = 2048          # Set to window non focused
HP_FLAG_WINDOW_TOPMOST = 4096            # Set to window always on top
HP_FLAG_WINDOW_ALWAYS_RUN = 256          # Set to allow windows running while minimized
HP_FLAG_WINDOW_TRANSPARENT = 16          # Set to allow transparent framebuffer
HP_FLAG_WINDOW_HIGHDPI = 8192            # Set to support HighDPI
HP_FLAG_WINDOW_MOUSE_PASSTHROUGH = 16384 # Set to support mouse passthrough, only supported when FLAG_WINDOW_UNDECORATED
HP_FLAG_BORDERLESS_WINDOWED_MODE = 32768 # Set to run program in borderless windowed mode
HP_FLAG_MSAA_4X_HINT = 32                # Set to try enabling MSAA 4X
HP_FLAG_INTERLACED_HINT = 65536          # Set to try enabling interlaced video format (for V3D)

module Hokusai
  class Backend
    def self.run(klass, &block)
      config = Backend::Config.new
      block.call config
      puts "After block"
      app = klass.mount
      puts "after mount"

      obj = new(app, config)
      puts "after new"
      obj.run
    end

    attr_reader :app, :config

    def initialize(app, config)
      @app = app
      @config = config
    end

    class Config
      attr_accessor :width, :height, :fps,
                  :title, :config_flags, :window_state_flags,
                  :automation_driver, :background, :after_load_cb,
                  :host, :port, :automated, :on_reload, :event_waiting, :touch,
                  :draw_fps, :log

      def initialize
        @width = 500
        @height = 500
        @fps = 60
        @draw_fps = false
        @title = "(Unknown Title)"
        @config_flags = HP_FLAG_WINDOW_RESIZABLE | HP_FLAG_VSYNC_HINT
        @window_state_flags = HP_FLAG_WINDOW_RESIZABLE
        @automation_driver = nil
        @background = Hokusai::Color.new(255, 255, 255)
        @after_load_cb = nil
        @host = "127.0.0.1"
        @port = 4333
        @automated = false
        @on_reload = ->(_){}
        @event_waiting = false
        @touch = false
        @log = false
      end

      def start_automation_driver
        raise ConfigError.new("Need a Hokusai::Driver in order to automate") if automation_driver.nil?

        automation_driver.serve(host, port)
      end

      def automate(host, port)
        self.host = host
        self.port = port
        self.automated = true
      end

      def after_load(&block)
        self.after_load_cb = block
      end

      def on_reload(&block)
        @on_reload = block
      end
    end
  end
end


HP_SHADER_UNIFORM_FLOAT = 0      # Shader uniform type: float
HP_SHADER_UNIFORM_VEC2 = 1       # Shader uniform type: vec2 (2 float)
HP_SHADER_UNIFORM_VEC3 = 2       # Shader uniform type: vec3 (3 float)
HP_SHADER_UNIFORM_VEC4 = 3       # Shader uniform type: vec4 (4 float)
HP_SHADER_UNIFORM_INT = 4        # Shader uniform type: int
HP_SHADER_UNIFORM_IVEC2 = 5      # Shader uniform type: ivec2 (2 int)
HP_SHADER_UNIFORM_IVEC3 = 6      # Shader uniform type: ivec3 (3 int)
HP_SHADER_UNIFORM_IVEC4 = 7      # Shader uniform type: ivec4 (4 int)
HP_SHADER_UNIFORM_UINT = 8       # Shader uniform type: unsigned int
HP_SHADER_UNIFORM_UIVEC2 = 9     # Shader uniform type: uivec2 (2 unsigned int)
HP_SHADER_UNIFORM_UIVEC3 = 10    # Shader uniform type: uivec3 (3 unsigned int)
HP_SHADER_UNIFORM_UIVEC4 = 11    # Shader uniform type: uivec4 (4 unsigned int)

# A backend agnostic library for authoring 
# desktop applications
# @author skinnyjames
module Hokusai
  # Access the font registry
  #
  # @return [Hokusai::FontRegistry]
  def self.fonts
    @fonts ||= FontRegistry.new
  end

  # Close the current window
  #
  # @return [void]
  def self.close_window
    @on_close_window&.call
  end

  # **Backend:** Provides the window close callback
  def self.on_close_window(&block)
    @on_close_window = block
  end

  # **Backend:** Provides the window restore callback
  def self.on_restore_window(&block)
    @on_restore_window = block
  end

  # Restores the current window
  #
  # @return [void]
  def self.restore_window
    @on_restore_window&.call
  end

  # Minimizes the current window
  #
  # @return [void]
  def self.minimize_window
    @on_minimize_window&.call
  end

  # **Backend** Provides the minimize window callback
  def self.on_minimize_window(&block)
    @on_minimize_window = block
  end

  # Maxmizes the current window
  #
  # @return [void]
  def self.maximize_window
    @on_maximize_window&.call
  end

  # **Backend** Provides the maximize window callback
  def self.on_maximize_window(&block)
    @on_maximize_window = block
  end

  # Sets the window position on the screen
  #
  # @param [Array<Float, Float>]
  # @return [void]
  def self.set_window_position(mouse)
    @on_set_window_position&.call(mouse)
  end

  # **Backend:** Provides the window position callback
  def self.on_set_window_position(&block)
    @on_set_window_position = block
  end

  # **Backend:** Provides the mouse position callback
  def self.on_set_mouse_position(&block)
    @on_set_mouse_position = block
  end

  # Sets the window position on the screen
  #
  # @param [Array<Float, Float>]
  # @return [void]
  def self.set_mouse_position(mouse)
    @on_set_mouse_position&.call(mouse)
  end

  def self.on_can_render(&block)
    @on_renderable = block
  end

  # Tells if a canvas is renderable
  # Useful for pruning unneeded renders
  #
  # @param [Hokusai::Canvas]
  # @return [Bool]
  def self.can_render(canvas)
    @on_renderable&.call(canvas)
  end

  def self.on_set_mouse_cursor(&block)
    @on_set_mouse_cursor = block
  end

  def self.set_mouse_cursor(type)
    @on_set_mouse_cursor&.call(type)
  end

  def self.on_copy(&block)
    @on_copy = block
  end

  def self.copy(text)
    @on_copy&.call(text)
  end

  # Mobile support
  def self.on_show_keyboard(&block)
    @on_show_keyboard = block
  end

  def self.show_keyboard
    @on_show_keyboard&.call
  end

  def self.on_hide_keyboard(&block)
    @on_hide_keyboard = block
  end

  def self.hide_keyboard
    @on_hide_keyboard&.call
  end

  def self.on_keyboard_visible(&block)
    @on_keyboard_visible = block
  end

  def self.keyboard_visible?
    @on_keyboard_visible&.call
  end

  def self.update(block)
    stack = [block]
    
    while block = stack.pop
      block.update

      stack.concat block.children.reverse
    end
  end
end

class Hokusai::Blocks::Empty < Hokusai::Block
  template <<~EOF
    [template]
      virtual
  EOF

  def render(canvas)
    yield canvas
  end
end

class Hokusai::Blocks::Vblock < Hokusai::Block
  template <<~EOF
    [template]
      slot
  EOF

  computed :padding, default: [0, 0, 0, 0], convert: Hokusai::Padding
  computed :background, default: nil, convert: Hokusai::Color
  computed :rounding, default: 0.0
  computed :outline, default: Hokusai::Outline.default, convert: Hokusai::Outline
  computed :outline_color, default: nil, convert: Hokusai::Color
  computed :reverse, default: false

  def render(canvas)
    canvas.vertical = true
    canvas.reverse = reverse

    if background.nil? && outline.nil?
      yield canvas
    else
      draw do
        rect(canvas.x, canvas.y, canvas.width, canvas.height) do |command|
          command.color = background
          command.outline = outline if outline
          command.outline_color = outline_color if outline_color
          command.round = rounding.to_f if rounding
          command.padding = padding
          canvas = command.trim_canvas(canvas)
        end
      end

      yield canvas
    end
  end
end

class Hokusai::Blocks::Hblock < Hokusai::Block
  template <<~EOF
    [template]
      slot
  EOF

  computed :padding, default: 0, convert: Hokusai::Padding
  computed :background, default: nil, convert: Hokusai::Color
  computed :rounding, default: 0.0
  computed :outline, default: Hokusai::Outline.default, convert: Hokusai::Outline
  computed :outline_color, default: nil, convert: Hokusai::Color
  computed :reverse, default: false

  def render(canvas)
    canvas.vertical = false
    canvas.reverse = reverse

    if background.nil? && outline.nil?
      yield canvas
    else
      draw do
        rect(canvas.x, canvas.y, canvas.width, canvas.height) do |command|
          command.color = background if background
          command.outline = outline if outline
          command.outline_color = outline_color if outline_color
          command.round = rounding.to_f if rounding
          command.padding = padding
          canvas = command.trim_canvas(canvas)
        end
      end

      yield canvas
    end
  end
end
# frozen_string_literal: true
class Hokusai::Blocks::Label < Hokusai::Block
  template <<~EOF
  [template]
    virtual
  EOF

  computed! :content
  computed :font, default: nil
  computed :size, default: 12
  computed :color, default: [33,33,33], convert: Hokusai::Color
  computed :padding, default: [5.0, 5.0, 5.0, 5.0], convert: Hokusai::Padding

  def initialize(**args)
    @content_width = 0.0
    @content_height = 0.0
    @updated = false
    @last_content = nil

    super
  end

  def render(canvas)
    if @last_content != content
      width, height = Hokusai.fonts.active.measure(content.to_s, size.to_i)
      node.meta.set_prop(:width, width + padding.right + padding.left)
      node.meta.set_prop(:height, height + padding.top + padding.bottom)
      emit("width_updated", width + padding.right + padding.left)

      @last_content = content
    end

    draw do
      text(content, canvas.x, canvas.y) do |command|
        command.color = color
        command.size = size
        command.padding = padding
        command.font = font unless font.nil?
      end
    end
  end
end

class Hokusai::Blocks::Rect < Hokusai::Block
  template <<~EOF
    [template]
      slot
  EOF

  computed :color, default: nil, convert: Hokusai::Color
  computed :rounding, default: 0.0
  computed :outline, default: nil, convert: Hokusai::Outline
  computed :outline_color, default: nil, convert: Hokusai::Color

  def render(canvas)
    draw do
      rect(canvas.x, canvas.y, canvas.width, canvas.height) do |command|
        command.color = color unless color.nil?
        command.outline = outline unless outline.nil?
        command.outline_color = outline_color unless outline_color.nil?
        command.round = rounding
      end
    end

    yield canvas
  end
end
# frozen_string_literal: true

class Hokusai::Blocks::Button < Hokusai::Block
  template <<~EOF
    [template]
      rect {
        @click="emit_click"
        @hover="set_hovered"
        @mouseout="unset_hovered"
        :color="background_color"
        :height="button_height"
        :width="button_width"
        :rounding="rounding"
        :outline="outline"
        :outline_color="outline_color"
      }
        label {
          :padding="padding"
          :color="color"
          @width_updated="update_width"
          :content="content"
          :size="size"
        }
  EOF

  uses(label: Hokusai::Blocks::Label, rect: Hokusai::Blocks::Rect)

  DEFAULT_BACKGROUND = [39, 95, 206]
  DEFAULT_CLICKED_BACKGROUND = [24, 52, 109]
  DEFAULT_HOVERED_BACKGROUND = [242, 52, 109]

  computed :padding, default: [5.0, 15.0, 5.0, 15.0], convert: Hokusai::Padding
  computed :size, default: 24
  computed :rounding, default: 0.5
  computed :content, default: ""
  computed :outline, default: 0.0, convert: Hokusai::Outline
  computed :outline_color, default: nil, convert: Hokusai::Color
  computed :background, default: DEFAULT_BACKGROUND, convert: Hokusai::Color
  computed :hovered_background, default: DEFAULT_HOVERED_BACKGROUND, convert: Hokusai::Color
  computed :clicked_background, default: DEFAULT_CLICKED_BACKGROUND, convert: Hokusai::Color
  computed :color, default: [215, 213, 226], convert: Hokusai::Color

  attr_accessor :button_width

  def emit_click(event)
    @clicked = true

    event.stop

    emit("clicked", event)
  end

  def update_width(value)
    self.button_width = value + (outline.right)
  end

  def set_hovered(event)
    @hovered = true
    @clicked = event.left.down

    Hokusai.set_mouse_cursor(:pointer)
  end

  def unset_hovered(_)
    @clicked = false

    if @hovered
      Hokusai.set_mouse_cursor(:default)
    end

    @hovered = false
  end

  def button_height
    size + padding.top + padding.bottom
  end

  def after_updated
    node.meta.props[:height] = button_height
  end

  def background_color
    @hovered ? (@clicked ? clicked_background : hovered_background) : background
  end

  def render(canvas)
    canvas.height = button_height
    canvas.width = button_width

    yield canvas
  end

  def initialize(**args)
    @button_width = 0.0
    @hovered = false
    @clicked = false

    super
  end
end

class Hokusai::Blocks::Circle < Hokusai::Block
  template <<~EOF
    [template]
      virtual
  EOF

  computed :radius, default: 10.0, convert: proc(&:to_f)
  computed :color, default: [255,255,255], convert: Hokusai::Color
  computed :outline, default: nil
  computed :outline_color, default: [0,0,0,0], convert: Hokusai::Color

  def render(canvas)
    x = canvas.x + (canvas.width / 2)
    y = canvas.y + canvas.height / 2

    draw do
      circle(x, y, radius) do |command|
        command.color = color
        if outline
          command.outline = outline
          command.outline_color = outline_color
        end
      end
    end

    yield canvas
  end
end

class Hokusai::Blocks::Checkbox < Hokusai::Block
  template <<~EOF
    [template]
      rect#checkbox {
        @click="check"
        :width="size"
        :height="size"
        :color="color"
      }
        [if="checked"]
          circle { :radius="circle_size" :color="circle_color" }
  EOF

  uses(
    rect: Hokusai::Blocks::Rect,
    circle: Hokusai::Blocks::Circle,
    empty: Hokusai::Blocks::Empty
  )

  DEFAULT_COLOR = [184,201,219]
  DEFAULT_CIRCLE_COLOR = [44, 113, 183]

  computed :color, default: DEFAULT_COLOR, convert: Hokusai::Color
  computed :circle_color, default: DEFAULT_CIRCLE_COLOR, convert: Hokusai::Color
  computed :size, default: 25.0

  attr_accessor :checked

  def circle_size
    (size.to_f * 0.35)
  end

  def check(event)
    self.checked = !checked

    emit("check", checked)
  end

  def initialize(**args)
    @checked = false

    super
  end

  def render(canvas)
    canvas.width = size.to_f
    canvas.height = size.to_f

    yield canvas
  end
end

class Hokusai::Blocks::ScissorBegin < Hokusai::Block
  template <<~EOF
  [template]
    slot
  EOF

  computed :offset, default: 0.0, convert: proc(&:to_f)
  computed :auto, default: true

  def render(canvas)
    draw do
      scissor_begin(canvas.x, canvas.y, canvas.width, canvas.height)
    end

    canvas.y -= offset if auto
    canvas.offset_y = offset

    yield canvas
  end
end
class Hokusai::Blocks::ScissorEnd < Hokusai::Block
  template <<~EOF
  [template]
    virtual
  EOF

  def render(canvas)
    draw do
      scissor_end
    end
  end
end

class Hokusai::Blocks::Clipped < Hokusai::Block
  style <<-EOF
  [style]
  scissorStyle {
    height: 0.0;
    width: 0.0;
  }
  EOF

  template <<-EOF
  [template]
    scissorbegin { :auto="auto" :offset="offset" }
      slot
      scissorend { ...scissorStyle }
  EOF

  uses(
    scissorbegin: Hokusai::Blocks::ScissorBegin,
    scissorend: Hokusai::Blocks::ScissorEnd,
  )

  # automatically subtracts the offset from canvas.y
  computed :auto, default: true
  computed :offset, default: 0.0
end
class Hokusai::Blocks::Cursor < Hokusai::Block
  template <<~EOF
    [template]
      virtual
  EOF

  DEFAULT_COLOR = [255,0,0,244]

  computed :x, default: 0.0
  computed :y, default: 0.0
  computed :show, default: false
  computed :speed, default: 0.5
  computed :cursor_width, default: 2.0
  computed :cursor_height, default: 0.0
  computed :color, default: DEFAULT_COLOR, convert: Hokusai::Color

  inject :selection

  def initialize(**args)
    @active = false
    @iteration = 0

    super
  end

  def before_updated
    frames = speed * 30

    @active = @iteration < frames

    if @iteration >= 30
      @iteration = 0
    else
      @iteration += 1
    end
  end

  def render(canvas)
    diff = selection&.diff || 0.0
    
    if show
      draw do
        if @active
          rect(x, y + diff, cursor_width, cursor_height) do |command|
            command.color = color
          end
        end
      end
    end

    yield canvas
  end
end
# require "pathname"

class Hokusai::Blocks::Image < Hokusai::Block
  template <<~EOF
    [template]
      virtual
  EOF

  computed! :source
  computed :width, default: nil
  computed :height, default: nil
  computed :padding, default: Hokusai::Padding.new(0.0, 0.0, 0.0, 0.0), convert: Hokusai::Padding

  def render(canvas)
    src = Pathname.new(source).absolute? ? source : "#{File.dirname(caller[-1].split(":")[0])}/#{source}"

    draw do
      image(src, canvas.x + padding.left, canvas.y + padding.top, (width&.to_f || canvas.width) - padding.right, (height&.to_f || canvas.height) - padding.bottom)
    end

    yield canvas
  end
end
class Hokusai::Blocks::SVG < Hokusai::Block
  template <<~EOF
    [template]
      virtual
  EOF

  computed! :source
  computed :size, default: 12, convert: proc(&:to_i)
  computed :color, default: [255,255,255], convert: Hokusai::Color

  def render(canvas)
    draw do
      svg(source, canvas.x, canvas.y, size, size) do |command|
        command.color = color
      end
    end

    yield canvas
  end
end
class Hokusai::Blocks::Toggle < Hokusai::Block
  template <<-EOF
  [template]
    empty { @click="toggle" }
  EOF

  uses(empty: Hokusai::Blocks::Empty)

  computed :size, default: 30.0, convert: proc(&:to_f)
  computed :active_color, default: [137, 126, 186], convert: Hokusai::Color
  computed :inactive_color, default: [61, 57, 81], convert: Hokusai::Color
  computed :color, default: [215, 212, 226], convert: Hokusai::Color

  attr_accessor :toggled

  def toggle(_)
    self.toggled = !toggled

    emit("toggle", value: toggled)
  end

  def computed_color
    toggled ? active_color : inactive_color
  end

  def initialize(**args)
    @toggled = false

    super
  end

  def render(canvas)
    width = size * 2
    radius = size / 2

    start = toggled ? (canvas.x + width - radius) : canvas.x + radius

    draw do
      rect(canvas.x, canvas.y, width.to_f, size) do |command|
        command.color = computed_color
        command.round = size
        command.padding = Hokusai::Padding.convert(20)
      end

      circle(start, canvas.y + radius, radius) do |command|
        command.color = color
      end
    end

    canvas.width = size * 2
    canvas.height = size

    yield(canvas)
  end
end
class Hokusai::Blocks::Scrollbar < Hokusai::Block
  style <<~EOF
  [style]
  scrollbar {
    cursor: "pointer";
  }
  EOF
  template <<~EOF
    [template]
      vblock.scrollbar {
        ...scrollbar
        @mousedown="scroll_start"
        @mousemove="scroll_handle"
        :background="background"
      }
        rect.top {
          :height="scroll_top_height"
        }
          empty
        rect.control {
          :color="control_color"
          :height="control_height"
          :rounding="control_rounding"
          :outline="control_padding"
          outline_color="0,0,0,0"
        }
          empty
        rect.bottom
          empty
  EOF

  uses(
    vblock: Hokusai::Blocks::Vblock,
    rect: Hokusai::Blocks::Rect,
    empty: Hokusai::Blocks::Empty
  )

  computed :goto, default: nil
  computed :background, default: [22,22,22], convert: Hokusai::Color
  computed :control_color, default: [66,66,66], convert: Hokusai::Color
  computed :control_height, default: 20.0, convert: proc(&:to_f)
  computed :control_rounding, default: 0.75, convert: proc(&:to_f)
  computed :control_padding, default: 2.0, convert: proc(&:to_f)

  attr_accessor :scroll_y, :scrolling, :height, :offset

  def scroll_start(event)
    self.scrolling = true
    do_goto(event.pos.y)

    event.stop
  end

  def scroll_handle(event)
    if event.left.down && scrolling
      do_goto(event.pos.y)

      event.stop
    else
      self.scrolling = false
    end
  end

  def scroll_top_height
    start = scroll_y
    control_middle = (control_height / 2)

    if start <= offset + control_middle
      return 0.0
    elsif start >= offset + height - control_middle
      return height - control_height
    else
      return scroll_y - offset - control_middle
    end

    0.0
  end

  def after_updated
    do_goto(goto) unless goto.nil?
  end

  def percent_scrolled
    return 0 if scroll_top_height === 0

    scroll_top_height / (height - control_height)
  end

  def do_goto(value)
    self.scroll_y = value.to_f

    emit("scroll", scroll_y, percent: percent_scrolled)
  end

  def initialize(**args)
    @scroll_y = 0.0
    @scrolling = false
    @height = 0.0
    @offset = 0.0

    super
  end

  def render(canvas)
    self.offset = canvas.y
    self.height = canvas.height

    yield(canvas)
  end
end
class Hokusai::Blocks::Dynamic < Hokusai::Block
  template <<~EOF
    [template]
      slot
  EOF

  computed :reverse, default: false

  def before_updated
    width, height = compute_size

    emit("size_updated", width, height)
  end

  def on_mounted
    compute_size
  end

  def compute_size
    h = 0.0
    w = 0.0

    children.each do |block|
      h += block.node.meta.get_prop?(:height)&.to_f || 0.0
      w += block.node.meta.get_prop?(:width)&.to_f || 0.0
    end

    node.meta.set_prop(:height, h)

    [w, h]
  end

  def render(canvas)
    canvas.vertical = true
    canvas.reverse = (reverse == true || reverse == "true")

    yield canvas
  end
end
class Hokusai::Blocks::Panel < Hokusai::Block
  template <<~EOF
    [template]
      hblock {
        :background="background"
        @wheel="wheel_handle"
      }
        clipped { :auto="autoclip" :offset="offset" }
          dynamic { @size_updated="set_size" }
            slot
        [if="scroll_active"]
          scrollbar.scroller {
            @scroll="scroll_complete"
            :top="panel_top"
            :goto="scrollbar_goto"
            :width="scroll_width"
            :background="scroll_background"
            :control_color="scroll_color"
            :control_height="scroll_control_height"
          }
  EOF

  uses(
    clipped: Hokusai::Blocks::Clipped,
    dynamic: Hokusai::Blocks::Dynamic,
    hblock: Hokusai::Blocks::Hblock,
    scrollbar: Hokusai::Blocks::Scrollbar
  )

  computed :align, default: "top", convert: proc(&:to_s)
  computed :scroll_goto, default: nil
  computed :scroll_width, default: 14.0, convert: proc(&:to_f)
  computed :scroll_background, default: nil, convert: Hokusai::Color
  computed :scroll_color, default: nil, convert: Hokusai::Color
  computed :background, default: nil, convert: Hokusai::Color
  computed :autoclip, default: true

  provide :panel_offset, :offset
  provide :panel_content_height, :content_height
  provide :panel_height, :panel_height
  provide :panel_top, :panel_top

  inject :selection

  attr_accessor :top, :panel_height, :scroll_y, :scroll_percent,
                :scroll_goto_y, :clipped_offset, :clipped_content_height

  def initialize(**args)
    @top = nil
    @panel_height = 0.0
    @scroll_y = 0.0
    @scroll_percent = 0.0
    @scroll_goto_y = nil
    @clipped_offset = 0.0
    @clipped_content_height = 0.0

    super
  end

  def wheel_handle(event)
    return if clipped_content_height <= panel_height

    new_scroll_y = scroll_y + event.scroll * 20

    if y = top
      if new_scroll_y < y
        self.scroll_goto_y = y
      elsif new_scroll_y - top >= panel_height
        self.scroll_goto_y = panel_height if scroll_percent != 1.0
      else
        self.scroll_goto_y = new_scroll_y
      end
    end
  end

  def panel_top
    top || 0.0
  end

  def set_size(_, height)
    if panel_height != clipped_content_height || clipped_content_height.zero?
      self.clipped_content_height = height
      # self.scroll_goto_y = self.scroll_y unless scroll_y == top
    end
  end

  def offset
    ((panel_content_height * scroll_percent) - (panel_height * scroll_percent))
  end

  def content_height
    clipped_content_height
  end

  def panel_content_height
    clipped_content_height < panel_height ? panel_height : clipped_content_height
  end

  def scroll_active
    clipped_content_height > panel_height
  end

  def scroll_complete(y, percent:)
    self.scroll_y = y
    self.scroll_percent = percent
    self.scroll_goto_y = nil

    # todo handle selection

    emit("scroll", y, percent: percent)
  end

  def scrollbar_goto
    scroll_goto_y || scroll_goto
  end

  def scroll_control_height
    return 20.0 if panel_height <= 0.0

    val = (panel_height / panel_content_height) * panel_height
    val < 20.0 ? 20.0 : val
  end

  def render(canvas)
    self.top = canvas.y
    self.panel_height = canvas.height

    yield canvas
  end
end

module Hokusai::Util
  class Wrapped
    attr_accessor :y
    attr_accessor :text, :x, :width, :height, :extra, :widths, :positions
    
    def initialize(text, rect, extra, widths:, positions:)
      @text = text
      @x = rect.x
      @y = rect.y
      @width = rect.width
      @height = rect.height
      @widths = widths
      @extra = extra
      @positions = positions
    end

    def range
      positions.first..positions.last
    end
  end

  class WrapCachePayload
    attr_accessor :copy, :positions, :cursor
    
    def initialize(copy, positions, cursor)
      @copy = copy
      @positions = positions
      @cursor = cursor
    end
  end

  # A cache that stores the results of WrapStream.
  # Utiltiy methods are provided to quickly fetch a subset of tokens
  # Based on a given window's coordinates (canvas)
  class WrapCache
    attr_accessor :tokens

    # returns range denoting the index of the changed lines
    # from 2 different strings.
    # NOTE: the change must be consecutive
    def self.diff(first, second)
      arr = (0..first.length).to_a

      v = arr.bsearch do |i|
        first.rindex(second[0..i]) != 0
      end

      # bounds checks
      v = first.size if v.nil?
      v -= 1 if first[v] == "\n"

      a = 0
      while true
        if first[v] == "\n"
          a = v + 1
          break
        elsif v.zero?
          a = v
          break
        end
        v -= 1
      end

      b = a
      while true
        if first[b].nil?
          b = first.size - 1
          break
        elsif first[b] == "\n"
          break
        end
        b += 1
      end

      a..b
    end

    def initialize
      @tokens = []
    end

    def <<(element)
      @tokens << element
    end

    def splice(stream, last_content, new_content, selection: nil)
      change_line_indicies = WrapCache.diff(last_content, new_content)
      new_changed_line_indicies = WrapCache.diff(new_content, last_content)

      new_data = new_content[new_changed_line_indicies]
      old_text_callback = stream.on_text_cb
      records = []
      # the height of the new records
      records_height = 0.0

      stream.on_text do |wrapped|
        unless wrapped.positions.empty?
          records_height += wrapped.height
          wrapped.positions.map! do |pos|
            pos + change_line_indicies.begin
          end
          records << wrapped
        end
      end

      stream.wrap(new_data, nil)
      stream.flush

      # puts ["original.tokens.last.y", tokens.last.y].inspect

      # splice in new tokens
      #
      # update the new positions
      # NOTE: still need to udpate the y positions with the 
      # records.each do |record|
      #   records_height += record.height
      #   record.positions.map! do |pos|
      #     pos + change_line_indicies.begin
      #   end
      # end

      diff_pos = (new_changed_line_indicies.end - change_line_indicies.end)
      new_tokens = []
      found = false
      last_token = nil
      new_last_tokens_height = 0.0
      last_tokens_height = 0.0
      insert_index = 0

      while token = tokens.shift
        next if token.positions.empty?
        if token.range.begin >= change_line_indicies.begin && token.range.end <= change_line_indicies.end
          # this is a match
          # we want to remove these tokens from the list...and then sub in our new tokens.
          last_token = token
          last_tokens_height += token.height
          found = true
          next
        end

        if found
          token.y += (records_height - last_tokens_height)

          token.positions.map! do |pos|
            pos + diff_pos
          end
        else
          insert_index += 1
          new_last_tokens_height += token.height
        end

        new_tokens << token
      end

      records.each do |record|
        record.y += new_last_tokens_height
      end

      # puts ["insert", records.first.y, records.map(&:height).sum, insert_index, new_last_tokens_height].inspect

      new_tokens.insert(insert_index, *records)
      self.tokens = new_tokens
      

      # i = 0
      # tokens.each do |token|
      #   # puts ["token", token].inspect
      #   token.positions.each do |n|
      #     if n != i
      #       puts ["Mismatch token", token, i, n].inspect
      #     end

      #     i += 1
      #   end
      # end

      # restore callback
      stream.on_text(&old_text_callback)
      # return y
      tokens.last.y + tokens.last.height
    end

    def bsearch(canvas)
      low = 0
      high = tokens.size - 1

      while low <= high
        mid = low + (high - low) / 2

        if matches(tokens[mid], canvas)
          return mid
        end

        if tokens[mid].y > canvas.y
          high = mid - 1
        end

        if tokens[mid].y < canvas.y
          low = mid + 1
        end
      end

      return nil
    end

    def matches(wrapped, canvas)
      wrapped.y >= canvas.y && wrapped.y <= canvas.y + canvas.height
    end

    #  arrows = cursor index
    #  letters = selected positions
    #                          
    #  │     │      │     │     │  
    #  │  A  │   B  │  C  │  D  │  
    #  │     │      │     │     │  
    #  ▼  0  ▼   1  ▼  2  ▼  3  ▼  
    #                           
    #  -1    0      1     2     3  
    #                            
    def selected_area_for_tokens(tokens, selector, copy: false, padding: Hokusai::Padding.default)
      return if selector.nil? || !selector.selecting?

      copy_buffer = ""
      x = nil
      tw = 0.0
      cy = nil
      position_buffer = []
      cursor = nil
      pcursor = nil

      tokens.each do |token|
        tx = token.x + padding.left
        ty = token.y + padding.top

        if token.y != cy
          x = nil
          cy = token.y
          tw = 0.0
        end

        token.widths.each_with_index do |w, i|
          by = selector.geom.frozen? ? ty : ty - selector.offset_y
          sy = ty

          if (selector.geom? && selector.geom.selected(tx, by, w, token.height))
            if (selector.geom.left? || selector.geom.up?)
              cursor ||= [tx, sy, 0.5, token.height]
              pcursor ||= token.positions[i]
            else
              # puts ["set selection cursor: #{sy}"]
              cursor = [tx + w, sy, 0.5, token.height]
              pcursor = token.positions[i]
            end

            position_buffer << token.positions[i]

            if copy
              copy_buffer += token.text[i]
            end

            if x.nil?
              x = tx
            end

            tw += w
          elsif selector.pos? && selector.pos.selected(token.positions[i])
            # puts ["pos 1"]
            if selector.pos.cursor_index == selector.pos.positions.first
              cursor ||= [tx, sy, 0.5, token.height]
              pcursor ||= token.positions[i]
            elsif selector.pos.cursor_index == selector.pos.positions.last
              cursor = [tx + w, sy, 0.5, token.height]
              pcursor = token.positions[i]
            elsif selector.pos.cursor_index + 1 == token.positions[i]
              cursor = [tx, sy, 0.5, token.height]
              pcursor = token.positions[i] - 1
            end

            position_buffer << token.positions[i]

            if copy
              copy_buffer += token.text[i]
            end

            if x.nil?
              x = tx
            end

            tw += w

          # [0, [0]]
          elsif selector.pos? && selector.pos.cursor_index && selector.pos.cursor_index + 1 == token.positions[i]
            # puts "pos 2"
            cursor = [tx, sy, 0.5, token.height]
            pcursor = token.positions[i] - 1
            # position_buffer = selector.pos.positions

            # if copy
            #   copy_buffer += token.text[i]
            # end

          elsif selector.pos? && selector.pos.cursor_index && selector.pos.cursor_index == token.positions[i]
            # puts "pos 3"
            cursor = [tx + w, sy, 0.5, token.height]
            pcursor = selector.pos.cursor_index
            # position_buffer = selector.pos.positions
          elsif selector.geom? && selector.geom.clicked(tx, by, (w / 2), token.height)
            cursor = [tx, sy, 0.5, token.height]
            pcursor = token.positions[i] - 1
            # puts "setting cursor #{sy}"

          elsif selector.geom? && selector.geom.clicked(tx + (w/2.0), by, (w/2.0), token.height)
            # puts "geom click 2"
            cursor = [tx + w, sy, 0.5, token.height]
            pcursor = token.positions[i]
          end
          
          tx += w
        end

        if !x.nil?
          ay = cy + padding.top - selector.offset_y
          yield Hokusai::Rect.new(x, ay, tw, token.height)

          tw = 0.0
        end
      end

      selector.pos.cursor_index = pcursor
      selector.pos.positions = position_buffer
      selector.geom.cursor = cursor

      WrapCachePayload.new(copy_buffer, position_buffer, pcursor)
    end

    def tokens_for(canvas)
      index = bsearch(canvas)
      return [] if index.nil?
      lindex = index.zero? ? index : index - 1
      rindex = index + 1

      while rindex < tokens.size - 1 && matches(tokens[rindex], canvas)
        rindex += 1
      end

      while lindex > 0 && matches(tokens[lindex], canvas)
        lindex -= 1
      end

      tokens[lindex..rindex].clone
    end
  end

  # A disposable streaming text wrapper
  # tokens can be appended onto it, where it they will break on a given width.
  # Opaque payloads can be passed for each token, which will be provided to callbacks.
  # This makes it suitable for processing and wrapping markdown/html/tokenized text
  #
  # height of the wrapped text is tracked with `stream#y`
  class WrapStream
    attr_accessor :buffer, :x, :y, :origin_y, :current_width, :stack, :widths, :current_position, :positions, :on_text_cb
    attr_reader :width, :origin_x, :on_text_cb

    def initialize(width, origin_x = 0.0, origin_y = 0.0, &measure)
      @width = width            # the width of the container for this wrap
      @measure_cb = measure     # a measure callback that returns the width/height of a given char (takes 2 params: a char and an token payload)
      @on_text_cb = ->(_) {}    # a callback that receives a wrapped token for a given line.  (takes a Hokusai::Util::Wrapped paramter)

      @origin_x = origin_x      # the origin x coordinate, x will reset to this
      @x = origin_x             # the marker for x coord, this is used to track against the width of a given line
      @y = origin_y             # the marker for the y coord, this grows by <size> for each line, resulting in the height of the wrapped text
      @current_width = 0.0      # the current width of the buffer
      @stack = []               # a stack storing buffer offsets with their respective token payloads.
      @buffer = ""              # the current buffer that the stack represents.
      
      @current_position = 0     # the current char index
      @positions = []           # a stack of char positions, used for editing
      @widths = []              # a stack of char widths, used later in selection
    end

    NEW_LINE_REGEX = /\n/

    # Appends <text> to the wrap stream.
    # If the text supplies causes the buffer to grow beyond the supplied width
    # The buffer will be flushed to the <on_text_cb> callback.
    #
    # @param [String] text (text to append to this wrap stream)
    # @param [Object] extra (an opaque payload that will be passed to callbacks)
    def wrap(text, extra)
      offset = 0
      size = text.size
      
      # appends the initial stack value for this text
      stack << [((buffer.size)..(text.size + buffer.size - 1)), extra]

      # char-by-char processing.
      while offset < size
        char = text[offset]
        self.current_position = offset

        w, h = measure(char, extra)

        # this char is actually a newline.
        if NEW_LINE_REGEX.match(char)
          self.widths << 0
          self.buffer << char
          self.positions << current_position
          flush

          # append the rest of this text to the stack.
          stack << [(0...(text.size - offset - 1)), extra]
          self.y += h
          self.x = origin_x
          offset += 1

          next
        end

        # adding this char will extend beyond the provided width
        if w + current_width >= width
          # if this is a space in the second half of this line, 
          # split the buffer @ it's index and render
          idx = buffer.rindex(" ")
          if !idx.nil?
            cur = []
            nex = []

            found = false

            # we need to split up the buffer and the ranges.
            while payload = stack.shift
              range, xtra = payload

              # this range contains the space
              # we will split the stack here
              if range.include?(idx)
                cur << [(range.begin..idx), xtra]
                nex << [(0..(range.end - idx - 1)), xtra] unless idx == range.end
              
                found = true
              # the space has not been found
              # append to first stack
              elsif !found
                cur << payload
              # the space has been found
              # append to second stack.
              # (note: we need to subtract the idx from the range because 
              #        we are flushing everything before the space)
              else
                nex << [((range.begin - idx - 1)..(range.end - idx - 1)), xtra] 
              end
            end

            # get the string values from the buffer
            scur = buffer[0..idx]
            snex = buffer[(idx + 1)..-1]

            wcur = widths[0..idx]
            wnex = widths[(idx + 1)..-1]

            pcur = positions[0..idx]
            pnex = positions[(idx + 1)..-1]

            # set the buffer and stack to everything before the space
            self.buffer = scur
            self.widths = wcur
            self.stack = cur
            self.positions = pcur

            flush

            # set the buffer and stack to everything after the space
            self.buffer = snex + char
            self.widths = wnex.concat([w])
            self.positions = pnex.concat([current_position])
            self.stack = nex
            self.x = origin_x
            self.current_width = widths.sum#measure(buffer, xtra).first


            # bump the height
            self.y += h
          # no space: force a break on the char.
          else
            flush

            self.current_width = w
            self.y += h
            self.buffer = text[offset]
            self.widths = [w]
            self.positions = [current_position]
            stack << [(0...(text.size - offset)), xtra]
          end
        # append this char does NOT extend beyond the width
        else
          self.current_width += w
          buffer << char
          widths << w
          positions << current_position
        end

        offset += 1
      end
    end

    # Flushes the current buffer/stack.
    def flush
      stack.each do |(range, extra)|
        content = buffer[range]
        size = content.size
        content_width, content_height = measure(content, extra)

        wrap_and_call(content, content_width, content_height, extra)
        self.x += content_width
      end

      self.buffer = ""
      self.current_width = 0.0
      stack.clear
      widths.clear
      positions.clear
      self.x = origin_x
    end

    def on_text(&block)
      @on_text_cb = block
    end

    private

    def wrap_and_call(text, width, height, extra)
      rect = Hokusai::Rect.new(x, y, width, height)
      @on_text_cb.call Wrapped.new(text.dup, rect, extra, widths: widths.dup, positions: positions.dup)
    end

    def measure(string, extra)
      @measure_cb.call(string, extra)
    end
  end
end

module Hokusai::Util
  class GeometrySelection
    attr_accessor :start_x, :start_y, :stop_x, :stop_y,
                  :type, :cursor, :diff, :click_pos, :parent

    def initialize(parent)
      @parent = parent
      @type = :none         # state for the geometry selection (active/frozen/etc)
      @start_x = 0.0        # the x coordinate for the geometry
      @stary_y = 0.0        # the y coordinate for the geometry 
      @stop_x = 0.0
      @stop_y = 0.0
      @diff = 0.0
      @cursor = nil
      @click_pos = nil
    end

    def set_click_pos(x, y)
      @click_pos = [x, y]
    end

    def none?
      type == :none
    end

    def ready?
      type == :none || type == :frozen
    end

    def clear
      self.start_x = 0.0
      self.start_y = 0.0
      self.stop_x = 0.0
      self.stop_y = 0.0
      self.cursor = nil
    end

    def changed_direction?
      @changed_direction
    end

    def active?
      type == :active
    end

    def frozen?
      type == :frozen
    end

    def activate!
      self.type = :active
    end

    def freeze!
      self.type = :frozen
    end

    def coords
      [start_x, stop_x, start_y, stop_y]
    end

    def start(x, y)
      self.start_x = x
      self.start_y = y
      self.stop_x = x
      self.stop_y = y
      self.cursor = nil

      activate!
    end

    def stop(x, y)
      self.stop_x = x
      self.stop_y = y

      if up? && @direction == :down || down? && @direction == :up
        @changed_direction = true
      else
        @changed_direction = false
      end

      @direction = up? ? :up : :down
    end

    def up?(height = 0)
      stop_y < start_y - height
    end

    def down?(height = 0)
      start_y <= stop_y - height
    end

    def left?
      stop_x < start_x
    end

    def right?
      start_x <= stop_x
    end

    def cursor
      return nil unless @cursor

      return [@cursor[0], @cursor[1] - parent.offset_y, @cursor[2], @cursor[3]] if frozen?

      @cursor
    end

    def rect_selected(rect)
      selected(rect[0], rect[1], rect[2], rect[3])
    end

    def clicked(x,y,w,h)
      return false if click_pos.nil?

      pos = Hokusai::Rect.new(x, y, w, h)
      # pos.move_x_left
      pos.includes_x?(click_pos[0]) && pos.includes_y?(click_pos[1])
    end

    def selected(x, y, width, height)
      return false if none?

      if frozen?
        y -= parent.offset_y
      end

      sx = @start_x
      sy = @start_y
      ex = @stop_x
      ey = @stop_y

      down = sy <= ey
      up = ey < sy
      left = ex < sx
      right = sx <= ex

      rect = Hokusai::Rect.new(x, y, width, height)
      x_shifted_right = rect.move_x_right(1)
      y_shifted_up = rect.move_y_up(2)
      y_shifted_down = rect.move_y_down(2)
      end_y = y + height

      a = ((down &&
        # first line of multiline selection
        ((x_shifted_right > sx && end_y < ey && rect.includes_y?(sy)) ||
          # last line of multiline selection
          (x_shifted_right <= ex && y_shifted_up + height < ey && y > sy) ||
          # middle line (all selected)
          (y > sy && end_y < ey))) ||
        (up &&
          # first line of multiline selection
          ((x_shifted_right <= sx && y > ey && rect.includes_y?(sy)) ||
          # last line of multiline selection
            (x_shifted_right >= ex && y_shifted_down > ey && end_y < sy) ||
            # middle line (all selected)
            (y > ey && y + height < sy))) ||
        # single line selection
        ((rect.includes_y?(sy) && rect.includes_y?(ey)) &&
          ((left && x_shifted_right < sx && x_shifted_right > ex) || (right && x_shifted_right > sx && x_shifted_right < ex)))
      )

      a
    end
  end
end
module Hokusai::Util
  class PositionSelection
    attr_accessor :positions, :cursor_index, :direction, :active

    def initialize
      @cursor_index = nil
      @positions = []
      @direction = :right
      @active = false
    end

    def move(to, selecting)
      self.active = selecting
  
      return if cursor_index.nil?

      # puts ["before", to, cursor_index, positions].inspect
      
      case to
      when :right
        self.cursor_index += 1
        if selecting && !positions.empty? && cursor_index <= positions.last
          positions.shift
        elsif selecting
          positions << cursor_index 
        end

      when :left
        if selecting && !positions.empty? && cursor_index >= positions.last
          positions.pop
        elsif selecting
          positions.unshift cursor_index
        end
  
        self.cursor_index -= 1 unless cursor_index == -1
      end
    end

    def active?
      @active
    end

    def left?
      direction == :left
    end

    def right?
      direction == :right
    end

    def clear
      self.cursor_index = nil
      positions.clear
    end

    def selected(index)
      active && (positions.first..positions.last).include?(index)
    end

    def select(range)
      self.positions = range.to_a
    end
  end
end

module Hokusai::Util
  class SelectionNew
    attr_reader :geom, :pos
    attr_accessor :type, :offset_y, :diff, :cursor

    def initialize
      @geom = GeometrySelection.new(self)
      @pos = PositionSelection.new
      @type = :geom
      @offset_y = 0.0
      @diff = 0.0
      @cursor = nil
    end

    def clear
      pos.clear
      geom.clear
    end

    def cursor
      geom.cursor
    end

    def geom!
      pos.clear
      pos.cursor_index = nil

      self.type = :geom
    end

    def pos!
      geom.clear

      self.type = :pos
    end

    def geom?
      type == :geom
    end

    def pos?
      type == :pos
    end

    def left?
      geom? ? geom.left? : pos.left?
    end

    def right?
      geom? ? geom.right? : pos.right?
    end

    def up?
      geom? && geom.up?
    end

    def down?
      geom? && geom.down?
    end

    def selecting?
      !(geom.type == :none && geom.click_pos.nil?)
    end

    # should we show the cursor?
    def active?
      !cursor.nil?
    end
  end
end

class Hokusai::Blocks::Text < Hokusai::Block
  template <<~EOF
  [template]
    empty {
      @keypress="check_copy"
    }
  EOF

  uses(empty: Hokusai::Blocks::Empty)

  computed! :content
  computed :background, default: [255, 255, 255], convert: Hokusai::Color
  computed :color, default: [222,222,222], convert: Hokusai::Color
  computed :selection_color, default: [43, 63, 61], convert: Hokusai::Color
  computed :selection_color_to, default: [0, 33, 233], convert: Hokusai::Color
  computed :animate_selection, default: false
  computed :padding, default: [20.0, 20.0, 20.0, 20.0], convert: Hokusai::Padding
  computed :font, default: nil
  computed :size, default: 15, convert: proc(&:to_i)
  computed :copy_text, default: false

  inject :panel_top
  inject :panel_height
  inject :panel_content_height
  inject :panel_offset
  inject :selection

  attr_accessor :copying, :copy_buffer, :measure_map, :last_content, :breaked, :render_height, :last_size, :last_y,
                :heights_loaded

  def on_mounted
    @copying = false
    @last_content = nil
    @last_size = nil
    @last_y = nil
    @heights_loaded = false
    @copy_buffer = ""
    @measure_map = nil
    @render_height = 0.0
    @breaked = false

    @progress = 0
    @back = false
  end

  def check_copy(event)
    if (event.ctrl || event.super) && event.symbol == :c
      self.copying = true
    end
  end

  def user_font
     font ? Hokusai.fonts.get(font) : Hokusai.fonts.active
  end

  def wrap_cache(canvas, force = false)

    should_splice = last_content != content && !last_content.nil?

    return @wrap_cache unless force || should_splice || !heights_loaded || breaked || @wrap_cache.nil?

    # if there's no cache, new / wrap
    # if the heights aren't loaded - new / wrap
    # if the content changed - use / splice
    # if forced / resized - new / wrap
    if force || !heights_loaded || breaked || @wrap_cache.nil?
      @wrap_cache = Hokusai::Util::WrapCache.new
    end

    self.breaked = false

    # for one big text, we want to use panel_top because canvas.y get's fucked on scroll
    # for looped items, we wawnt to use canvas.y    
    # puts ["canvas.y stream", canvas.y, panel_offset].inspect
    stream = Hokusai::Util::WrapStream.new(width(canvas), canvas.x, canvas.y + (panel_offset || 0)) do |string, extra|
      if w = user_font.measure_char(string, size)
        [w, size]
      else
        [user_font.measure(string, size).first, size]
      end
    end

    if should_splice
      stream.y = @wrap_cache.splice(stream, last_content, content)
    else
      stream.on_text do |wrapped|
        @wrap_cache << wrapped
      end

      stream.wrap(content, nil)
    end

    stream.flush
    self.render_height = stream.y

    if !last_y.nil?
      self.heights_loaded = true
    end

    self.last_y = canvas.y
    self.last_content = content.dup
    self.last_size = size

    @wrap_cache
  end

  def on_resize(canvas)
    self.breaked = true
  end

  def width(canvas)
    canvas.width - padding.width
  end

  def should_refresh(canvas)
    if breaked || last_size != size || (!heights_loaded)
      return true
    end

    false
  end

  # A fragment shader to rotate tint on asteroids
  def fshader
    <<-EOF
    #version 330
    in vec4 fragColor;
    in vec2 fragTexCoord;
    out vec4 finalColor;
    uniform sampler2D texture0;
    uniform vec4 from;
    uniform vec4 to;
    uniform float progress;

    void main() {
      vec4 texelColor = texture(texture0, fragTexCoord) * fragColor;

      finalColor.a = texelColor.a;
      finalColor.rgb = mix(from, to, progress).rgb;
    }
    EOF
  end

  def render(canvas)
    poffset = panel_offset || canvas.y
    pheight = panel_height || canvas.height
    pcheight = panel_content_height ||= canvas.height
    pptop = panel_top.nil? ? canvas.y : panel_top - canvas.y
    ptop = canvas.y + poffset

    cache = wrap_cache(canvas, should_refresh(canvas))
    diff = 0.0

    if selection
      selection.offset_y = poffset if selection.geom.active?
      diff = selection.offset_y - poffset
      selection.diff = diff
    end

    draw do
      tokens = cache.tokens_for(Hokusai::Canvas.new(canvas.width, pheight, canvas.x + padding.left, poffset))
      pad = Hokusai::Padding.new(padding.top, 0.0, 0.0, padding.left)

      if selection && animate_selection
        shader_begin do |command|
          command.fragment_shader = fshader
          command.uniforms = {
            "from" => [selection_color.to_shader_value, HP_SHADER_UNIFORM_VEC4], 
            "to" => [selection_color_to.to_shader_value, HP_SHADER_UNIFORM_VEC4],
            "progress" => [@progress, HP_SHADER_UNIFORM_FLOAT]
          }
        end
      end

      copied = cache.selected_area_for_tokens(tokens, selection, copy: copying || copy_text, padding: pad) do |rect|
        rect(rect.x, rect.y + diff, rect.width, rect.height) do |command|
          command.color = selection_color
        end
      end

      emit("selected", copied) unless copied.nil?

      if copying
        Hokusai.copy(copied.copy)
        self.copying = false
      end

      if copy_text
        emit("copy", copied)
      end

      if selection && animate_selection
        shader_end
      end

      tokens.each do |wrapped|
        # handle selection
        rect = Hokusai::Rect.new(wrapped.x + pad.left, (wrapped.y - (panel_offset || 0.0)) + padding.top, wrapped.width, wrapped.height)
        # draw text
        text(wrapped.text, rect.x, rect.y) do |command|
          command.color = color
          command.size = size
          if font
            command.font = Hokusai.fonts.get(font)
          end
        end
      end
    end

    node.meta.set_prop(:height, render_height)
    emit("height_updated", render_height)

    if @back
      @progress -= 0.02
    else
      @progress += 0.02
    end

    if @progress >= 1 && !@back
      @back = true
    elsif @progress <= 0 && @back
      @progress = 0
      @back = false
    end

    yield canvas
  end
end

module Hokusai::Util
  class GeometrySelection
    attr_accessor :start_x, :start_y, :stop_x, :stop_y,
                  :type, :cursor, :diff, :click_pos, :parent

    def initialize(parent)
      @parent = parent
      @type = :none         # state for the geometry selection (active/frozen/etc)
      @start_x = 0.0        # the x coordinate for the geometry
      @stary_y = 0.0        # the y coordinate for the geometry 
      @stop_x = 0.0
      @stop_y = 0.0
      @diff = 0.0
      @cursor = nil
      @click_pos = nil
    end

    def set_click_pos(x, y)
      @click_pos = [x, y]
    end

    def none?
      type == :none
    end

    def ready?
      type == :none || type == :frozen
    end

    def clear
      self.start_x = 0.0
      self.start_y = 0.0
      self.stop_x = 0.0
      self.stop_y = 0.0
      self.cursor = nil
    end

    def changed_direction?
      @changed_direction
    end

    def active?
      type == :active
    end

    def frozen?
      type == :frozen
    end

    def activate!
      self.type = :active
    end

    def freeze!
      self.type = :frozen
    end

    def coords
      [start_x, stop_x, start_y, stop_y]
    end

    def start(x, y)
      self.start_x = x
      self.start_y = y
      self.stop_x = x
      self.stop_y = y
      self.cursor = nil

      activate!
    end

    def stop(x, y)
      self.stop_x = x
      self.stop_y = y

      if up? && @direction == :down || down? && @direction == :up
        @changed_direction = true
      else
        @changed_direction = false
      end

      @direction = up? ? :up : :down
    end

    def up?(height = 0)
      stop_y < start_y - height
    end

    def down?(height = 0)
      start_y <= stop_y - height
    end

    def left?
      stop_x < start_x
    end

    def right?
      start_x <= stop_x
    end

    def cursor
      return nil unless @cursor

      return [@cursor[0], @cursor[1] - parent.offset_y, @cursor[2], @cursor[3]] if frozen?

      @cursor
    end

    def rect_selected(rect)
      selected(rect[0], rect[1], rect[2], rect[3])
    end

    def clicked(x,y,w,h)
      return false if click_pos.nil?

      pos = Hokusai::Rect.new(x, y, w, h)
      # pos.move_x_left
      pos.includes_x?(click_pos[0]) && pos.includes_y?(click_pos[1])
    end

    def selected(x, y, width, height)
      return false if none?

      if frozen?
        y -= parent.offset_y
      end

      sx = @start_x
      sy = @start_y
      ex = @stop_x
      ey = @stop_y

      down = sy <= ey
      up = ey < sy
      left = ex < sx
      right = sx <= ex

      rect = Hokusai::Rect.new(x, y, width, height)
      x_shifted_right = rect.move_x_right(1)
      y_shifted_up = rect.move_y_up(2)
      y_shifted_down = rect.move_y_down(2)
      end_y = y + height

      a = ((down &&
        # first line of multiline selection
        ((x_shifted_right > sx && end_y < ey && rect.includes_y?(sy)) ||
          # last line of multiline selection
          (x_shifted_right <= ex && y_shifted_up + height < ey && y > sy) ||
          # middle line (all selected)
          (y > sy && end_y < ey))) ||
        (up &&
          # first line of multiline selection
          ((x_shifted_right <= sx && y > ey && rect.includes_y?(sy)) ||
          # last line of multiline selection
            (x_shifted_right >= ex && y_shifted_down > ey && end_y < sy) ||
            # middle line (all selected)
            (y > ey && y + height < sy))) ||
        # single line selection
        ((rect.includes_y?(sy) && rect.includes_y?(ey)) &&
          ((left && x_shifted_right < sx && x_shifted_right > ex) || (right && x_shifted_right > sx && x_shifted_right < ex)))
      )

      a
    end
  end
end
module Hokusai::Util
  class PositionSelection
    attr_accessor :positions, :cursor_index, :direction, :active

    def initialize
      @cursor_index = nil
      @positions = []
      @direction = :right
      @active = false
    end

    def move(to, selecting)
      self.active = selecting
  
      return if cursor_index.nil?

      # puts ["before", to, cursor_index, positions].inspect
      
      case to
      when :right
        self.cursor_index += 1
        if selecting && !positions.empty? && cursor_index <= positions.last
          positions.shift
        elsif selecting
          positions << cursor_index 
        end

      when :left
        if selecting && !positions.empty? && cursor_index >= positions.last
          positions.pop
        elsif selecting
          positions.unshift cursor_index
        end
  
        self.cursor_index -= 1 unless cursor_index == -1
      end
    end

    def active?
      @active
    end

    def left?
      direction == :left
    end

    def right?
      direction == :right
    end

    def clear
      self.cursor_index = nil
      positions.clear
    end

    def selected(index)
      active && (positions.first..positions.last).include?(index)
    end

    def select(range)
      self.positions = range.to_a
    end
  end
end

module Hokusai::Util
  class SelectionNew
    attr_reader :geom, :pos
    attr_accessor :type, :offset_y, :diff, :cursor

    def initialize
      @geom = GeometrySelection.new(self)
      @pos = PositionSelection.new
      @type = :geom
      @offset_y = 0.0
      @diff = 0.0
      @cursor = nil
    end

    def clear
      pos.clear
      geom.clear
    end

    def cursor
      geom.cursor
    end

    def geom!
      pos.clear
      pos.cursor_index = nil

      self.type = :geom
    end

    def pos!
      geom.clear

      self.type = :pos
    end

    def geom?
      type == :geom
    end

    def pos?
      type == :pos
    end

    def left?
      geom? ? geom.left? : pos.left?
    end

    def right?
      geom? ? geom.right? : pos.right?
    end

    def up?
      geom? && geom.up?
    end

    def down?
      geom? && geom.down?
    end

    def selecting?
      !(geom.type == :none && geom.click_pos.nil?)
    end

    # should we show the cursor?
    def active?
      !cursor.nil?
    end
  end
end

module Hokusai::Blocks
  class Selectable < Hokusai::Block
    template <<~EOF
      [template]
        vblock {
          @click="start_selection"
          @hover="update_selection"
        }
          slot
          cursor {
            height="0"
            :color="cursor_color"
            :x="cursor_x"
            :y="cursor_y"
            :cursor_height="cursor_height"
            :show="cursor_show"
          }
    EOF

    uses(
      vblock: Hokusai::Blocks::Vblock,
      cursor: Hokusai::Blocks::Cursor
    )

    computed :cursor_color, default: [255,22,22], convert: Hokusai::Color

    provide :selection, :selection

    attr_reader :selection

    def initialize(**args)
      @selection = Hokusai::Util::Selection.new

      super
    end

    def start_selection(event)
      if event.left.down && !selection.active?
        selection.clear
        selection.start(event.pos.x, event.pos.y)
      end
    end

    def update_selection(event)
      return unless selection.active?
      
      if event.left.up
        selection.freeze!
      elsif event.left.down
        selection.stop(event.pos.x, event.pos.y)
      end
    end

    def cursor_x
      cursor(0)
    end

    def cursor_y
      cursor(1)
    end

    def cursor_height
      cursor(3)
    end

    def cursor_show
      !selection.cursor.nil?
    end

    def cursor(index)
      return if selection.cursor.nil?

      selection.cursor[index]
    end
  end
end

module Hokusai::Util
  class Wrapped
    attr_accessor :y
    attr_accessor :text, :x, :width, :height, :extra, :widths, :positions
    
    def initialize(text, rect, extra, widths:, positions:)
      @text = text
      @x = rect.x
      @y = rect.y
      @width = rect.width
      @height = rect.height
      @widths = widths
      @extra = extra
      @positions = positions
    end

    def range
      positions.first..positions.last
    end
  end

  class WrapCachePayload
    attr_accessor :copy, :positions, :cursor
    
    def initialize(copy, positions, cursor)
      @copy = copy
      @positions = positions
      @cursor = cursor
    end
  end

  # A cache that stores the results of WrapStream.
  # Utiltiy methods are provided to quickly fetch a subset of tokens
  # Based on a given window's coordinates (canvas)
  class WrapCache
    attr_accessor :tokens

    # returns range denoting the index of the changed lines
    # from 2 different strings.
    # NOTE: the change must be consecutive
    def self.diff(first, second)
      arr = (0..first.length).to_a

      v = arr.bsearch do |i|
        first.rindex(second[0..i]) != 0
      end

      # bounds checks
      v = first.size if v.nil?
      v -= 1 if first[v] == "\n"

      a = 0
      while true
        if first[v] == "\n"
          a = v + 1
          break
        elsif v.zero?
          a = v
          break
        end
        v -= 1
      end

      b = a
      while true
        if first[b].nil?
          b = first.size - 1
          break
        elsif first[b] == "\n"
          break
        end
        b += 1
      end

      a..b
    end

    def initialize
      @tokens = []
    end

    def <<(element)
      @tokens << element
    end

    def splice(stream, last_content, new_content, selection: nil)
      change_line_indicies = WrapCache.diff(last_content, new_content)
      new_changed_line_indicies = WrapCache.diff(new_content, last_content)

      new_data = new_content[new_changed_line_indicies]
      old_text_callback = stream.on_text_cb
      records = []
      # the height of the new records
      records_height = 0.0

      stream.on_text do |wrapped|
        unless wrapped.positions.empty?
          records_height += wrapped.height
          wrapped.positions.map! do |pos|
            pos + change_line_indicies.begin
          end
          records << wrapped
        end
      end

      stream.wrap(new_data, nil)
      stream.flush

      # puts ["original.tokens.last.y", tokens.last.y].inspect

      # splice in new tokens
      #
      # update the new positions
      # NOTE: still need to udpate the y positions with the 
      # records.each do |record|
      #   records_height += record.height
      #   record.positions.map! do |pos|
      #     pos + change_line_indicies.begin
      #   end
      # end

      diff_pos = (new_changed_line_indicies.end - change_line_indicies.end)
      new_tokens = []
      found = false
      last_token = nil
      new_last_tokens_height = 0.0
      last_tokens_height = 0.0
      insert_index = 0

      while token = tokens.shift
        next if token.positions.empty?
        if token.range.begin >= change_line_indicies.begin && token.range.end <= change_line_indicies.end
          # this is a match
          # we want to remove these tokens from the list...and then sub in our new tokens.
          last_token = token
          last_tokens_height += token.height
          found = true
          next
        end

        if found
          token.y += (records_height - last_tokens_height)

          token.positions.map! do |pos|
            pos + diff_pos
          end
        else
          insert_index += 1
          new_last_tokens_height += token.height
        end

        new_tokens << token
      end

      records.each do |record|
        record.y += new_last_tokens_height
      end

      # puts ["insert", records.first.y, records.map(&:height).sum, insert_index, new_last_tokens_height].inspect

      new_tokens.insert(insert_index, *records)
      self.tokens = new_tokens
      

      # i = 0
      # tokens.each do |token|
      #   # puts ["token", token].inspect
      #   token.positions.each do |n|
      #     if n != i
      #       puts ["Mismatch token", token, i, n].inspect
      #     end

      #     i += 1
      #   end
      # end

      # restore callback
      stream.on_text(&old_text_callback)
      # return y
      tokens.last.y + tokens.last.height
    end

    def bsearch(canvas)
      low = 0
      high = tokens.size - 1

      while low <= high
        mid = low + (high - low) / 2

        if matches(tokens[mid], canvas)
          return mid
        end

        if tokens[mid].y > canvas.y
          high = mid - 1
        end

        if tokens[mid].y < canvas.y
          low = mid + 1
        end
      end

      return nil
    end

    def matches(wrapped, canvas)
      wrapped.y >= canvas.y && wrapped.y <= canvas.y + canvas.height
    end

    #  arrows = cursor index
    #  letters = selected positions
    #                          
    #  │     │      │     │     │  
    #  │  A  │   B  │  C  │  D  │  
    #  │     │      │     │     │  
    #  ▼  0  ▼   1  ▼  2  ▼  3  ▼  
    #                           
    #  -1    0      1     2     3  
    #                            
    def selected_area_for_tokens(tokens, selector, copy: false, padding: Hokusai::Padding.default)
      return if selector.nil? || !selector.selecting?

      copy_buffer = ""
      x = nil
      tw = 0.0
      cy = nil
      position_buffer = []
      cursor = nil
      pcursor = nil

      tokens.each do |token|
        tx = token.x + padding.left
        ty = token.y + padding.top

        if token.y != cy
          x = nil
          cy = token.y
          tw = 0.0
        end

        token.widths.each_with_index do |w, i|
          by = selector.geom.frozen? ? ty : ty - selector.offset_y
          sy = ty

          if (selector.geom? && selector.geom.selected(tx, by, w, token.height))
            if (selector.geom.left? || selector.geom.up?)
              cursor ||= [tx, sy, 0.5, token.height]
              pcursor ||= token.positions[i]
            else
              # puts ["set selection cursor: #{sy}"]
              cursor = [tx + w, sy, 0.5, token.height]
              pcursor = token.positions[i]
            end

            position_buffer << token.positions[i]

            if copy
              copy_buffer += token.text[i]
            end

            if x.nil?
              x = tx
            end

            tw += w
          elsif selector.pos? && selector.pos.selected(token.positions[i])
            # puts ["pos 1"]
            if selector.pos.cursor_index == selector.pos.positions.first
              cursor ||= [tx, sy, 0.5, token.height]
              pcursor ||= token.positions[i]
            elsif selector.pos.cursor_index == selector.pos.positions.last
              cursor = [tx + w, sy, 0.5, token.height]
              pcursor = token.positions[i]
            elsif selector.pos.cursor_index + 1 == token.positions[i]
              cursor = [tx, sy, 0.5, token.height]
              pcursor = token.positions[i] - 1
            end

            position_buffer << token.positions[i]

            if copy
              copy_buffer += token.text[i]
            end

            if x.nil?
              x = tx
            end

            tw += w

          # [0, [0]]
          elsif selector.pos? && selector.pos.cursor_index && selector.pos.cursor_index + 1 == token.positions[i]
            # puts "pos 2"
            cursor = [tx, sy, 0.5, token.height]
            pcursor = token.positions[i] - 1
            # position_buffer = selector.pos.positions

            # if copy
            #   copy_buffer += token.text[i]
            # end

          elsif selector.pos? && selector.pos.cursor_index && selector.pos.cursor_index == token.positions[i]
            # puts "pos 3"
            cursor = [tx + w, sy, 0.5, token.height]
            pcursor = selector.pos.cursor_index
            # position_buffer = selector.pos.positions
          elsif selector.geom? && selector.geom.clicked(tx, by, (w / 2), token.height)
            cursor = [tx, sy, 0.5, token.height]
            pcursor = token.positions[i] - 1
            # puts "setting cursor #{sy}"

          elsif selector.geom? && selector.geom.clicked(tx + (w/2.0), by, (w/2.0), token.height)
            # puts "geom click 2"
            cursor = [tx + w, sy, 0.5, token.height]
            pcursor = token.positions[i]
          end
          
          tx += w
        end

        if !x.nil?
          ay = cy + padding.top - selector.offset_y
          yield Hokusai::Rect.new(x, ay, tw, token.height)

          tw = 0.0
        end
      end

      selector.pos.cursor_index = pcursor
      selector.pos.positions = position_buffer
      selector.geom.cursor = cursor

      WrapCachePayload.new(copy_buffer, position_buffer, pcursor)
    end

    def tokens_for(canvas)
      index = bsearch(canvas)
      return [] if index.nil?
      lindex = index.zero? ? index : index - 1
      rindex = index + 1

      while rindex < tokens.size - 1 && matches(tokens[rindex], canvas)
        rindex += 1
      end

      while lindex > 0 && matches(tokens[lindex], canvas)
        lindex -= 1
      end

      tokens[lindex..rindex].clone
    end
  end

  # A disposable streaming text wrapper
  # tokens can be appended onto it, where it they will break on a given width.
  # Opaque payloads can be passed for each token, which will be provided to callbacks.
  # This makes it suitable for processing and wrapping markdown/html/tokenized text
  #
  # height of the wrapped text is tracked with `stream#y`
  class WrapStream
    attr_accessor :buffer, :x, :y, :origin_y, :current_width, :stack, :widths, :current_position, :positions, :on_text_cb
    attr_reader :width, :origin_x, :on_text_cb

    def initialize(width, origin_x = 0.0, origin_y = 0.0, &measure)
      @width = width            # the width of the container for this wrap
      @measure_cb = measure     # a measure callback that returns the width/height of a given char (takes 2 params: a char and an token payload)
      @on_text_cb = ->(_) {}    # a callback that receives a wrapped token for a given line.  (takes a Hokusai::Util::Wrapped paramter)

      @origin_x = origin_x      # the origin x coordinate, x will reset to this
      @x = origin_x             # the marker for x coord, this is used to track against the width of a given line
      @y = origin_y             # the marker for the y coord, this grows by <size> for each line, resulting in the height of the wrapped text
      @current_width = 0.0      # the current width of the buffer
      @stack = []               # a stack storing buffer offsets with their respective token payloads.
      @buffer = ""              # the current buffer that the stack represents.
      
      @current_position = 0     # the current char index
      @positions = []           # a stack of char positions, used for editing
      @widths = []              # a stack of char widths, used later in selection
    end

    NEW_LINE_REGEX = /\n/

    # Appends <text> to the wrap stream.
    # If the text supplies causes the buffer to grow beyond the supplied width
    # The buffer will be flushed to the <on_text_cb> callback.
    #
    # @param [String] text (text to append to this wrap stream)
    # @param [Object] extra (an opaque payload that will be passed to callbacks)
    def wrap(text, extra)
      offset = 0
      size = text.size
      
      # appends the initial stack value for this text
      stack << [((buffer.size)..(text.size + buffer.size - 1)), extra]

      # char-by-char processing.
      while offset < size
        char = text[offset]
        self.current_position = offset

        w, h = measure(char, extra)

        # this char is actually a newline.
        if NEW_LINE_REGEX.match(char)
          self.widths << 0
          self.buffer << char
          self.positions << current_position
          flush

          # append the rest of this text to the stack.
          stack << [(0...(text.size - offset - 1)), extra]
          self.y += h
          self.x = origin_x
          offset += 1

          next
        end

        # adding this char will extend beyond the provided width
        if w + current_width >= width
          # if this is a space in the second half of this line, 
          # split the buffer @ it's index and render
          idx = buffer.rindex(" ")
          if !idx.nil?
            cur = []
            nex = []

            found = false

            # we need to split up the buffer and the ranges.
            while payload = stack.shift
              range, xtra = payload

              # this range contains the space
              # we will split the stack here
              if range.include?(idx)
                cur << [(range.begin..idx), xtra]
                nex << [(0..(range.end - idx - 1)), xtra] unless idx == range.end
              
                found = true
              # the space has not been found
              # append to first stack
              elsif !found
                cur << payload
              # the space has been found
              # append to second stack.
              # (note: we need to subtract the idx from the range because 
              #        we are flushing everything before the space)
              else
                nex << [((range.begin - idx - 1)..(range.end - idx - 1)), xtra] 
              end
            end

            # get the string values from the buffer
            scur = buffer[0..idx]
            snex = buffer[(idx + 1)..-1]

            wcur = widths[0..idx]
            wnex = widths[(idx + 1)..-1]

            pcur = positions[0..idx]
            pnex = positions[(idx + 1)..-1]

            # set the buffer and stack to everything before the space
            self.buffer = scur
            self.widths = wcur
            self.stack = cur
            self.positions = pcur

            flush

            # set the buffer and stack to everything after the space
            self.buffer = snex + char
            self.widths = wnex.concat([w])
            self.positions = pnex.concat([current_position])
            self.stack = nex
            self.x = origin_x
            self.current_width = widths.sum#measure(buffer, xtra).first


            # bump the height
            self.y += h
          # no space: force a break on the char.
          else
            flush

            self.current_width = w
            self.y += h
            self.buffer = text[offset]
            self.widths = [w]
            self.positions = [current_position]
            stack << [(0...(text.size - offset)), xtra]
          end
        # append this char does NOT extend beyond the width
        else
          self.current_width += w
          buffer << char
          widths << w
          positions << current_position
        end

        offset += 1
      end
    end

    # Flushes the current buffer/stack.
    def flush
      stack.each do |(range, extra)|
        content = buffer[range]
        size = content.size
        content_width, content_height = measure(content, extra)

        wrap_and_call(content, content_width, content_height, extra)
        self.x += content_width
      end

      self.buffer = ""
      self.current_width = 0.0
      stack.clear
      widths.clear
      positions.clear
      self.x = origin_x
    end

    def on_text(&block)
      @on_text_cb = block
    end

    private

    def wrap_and_call(text, width, height, extra)
      rect = Hokusai::Rect.new(x, y, width, height)
      @on_text_cb.call Wrapped.new(text.dup, rect, extra, widths: widths.dup, positions: positions.dup)
    end

    def measure(string, extra)
      @measure_cb.call(string, extra)
    end
  end
end

module Hokusai::Util
  class GeometrySelection
    attr_accessor :start_x, :start_y, :stop_x, :stop_y,
                  :type, :cursor, :diff, :click_pos, :parent

    def initialize(parent)
      @parent = parent
      @type = :none         # state for the geometry selection (active/frozen/etc)
      @start_x = 0.0        # the x coordinate for the geometry
      @stary_y = 0.0        # the y coordinate for the geometry 
      @stop_x = 0.0
      @stop_y = 0.0
      @diff = 0.0
      @cursor = nil
      @click_pos = nil
    end

    def set_click_pos(x, y)
      @click_pos = [x, y]
    end

    def none?
      type == :none
    end

    def ready?
      type == :none || type == :frozen
    end

    def clear
      self.start_x = 0.0
      self.start_y = 0.0
      self.stop_x = 0.0
      self.stop_y = 0.0
      self.cursor = nil
    end

    def changed_direction?
      @changed_direction
    end

    def active?
      type == :active
    end

    def frozen?
      type == :frozen
    end

    def activate!
      self.type = :active
    end

    def freeze!
      self.type = :frozen
    end

    def coords
      [start_x, stop_x, start_y, stop_y]
    end

    def start(x, y)
      self.start_x = x
      self.start_y = y
      self.stop_x = x
      self.stop_y = y
      self.cursor = nil

      activate!
    end

    def stop(x, y)
      self.stop_x = x
      self.stop_y = y

      if up? && @direction == :down || down? && @direction == :up
        @changed_direction = true
      else
        @changed_direction = false
      end

      @direction = up? ? :up : :down
    end

    def up?(height = 0)
      stop_y < start_y - height
    end

    def down?(height = 0)
      start_y <= stop_y - height
    end

    def left?
      stop_x < start_x
    end

    def right?
      start_x <= stop_x
    end

    def cursor
      return nil unless @cursor

      return [@cursor[0], @cursor[1] - parent.offset_y, @cursor[2], @cursor[3]] if frozen?

      @cursor
    end

    def rect_selected(rect)
      selected(rect[0], rect[1], rect[2], rect[3])
    end

    def clicked(x,y,w,h)
      return false if click_pos.nil?

      pos = Hokusai::Rect.new(x, y, w, h)
      # pos.move_x_left
      pos.includes_x?(click_pos[0]) && pos.includes_y?(click_pos[1])
    end

    def selected(x, y, width, height)
      return false if none?

      if frozen?
        y -= parent.offset_y
      end

      sx = @start_x
      sy = @start_y
      ex = @stop_x
      ey = @stop_y

      down = sy <= ey
      up = ey < sy
      left = ex < sx
      right = sx <= ex

      rect = Hokusai::Rect.new(x, y, width, height)
      x_shifted_right = rect.move_x_right(1)
      y_shifted_up = rect.move_y_up(2)
      y_shifted_down = rect.move_y_down(2)
      end_y = y + height

      a = ((down &&
        # first line of multiline selection
        ((x_shifted_right > sx && end_y < ey && rect.includes_y?(sy)) ||
          # last line of multiline selection
          (x_shifted_right <= ex && y_shifted_up + height < ey && y > sy) ||
          # middle line (all selected)
          (y > sy && end_y < ey))) ||
        (up &&
          # first line of multiline selection
          ((x_shifted_right <= sx && y > ey && rect.includes_y?(sy)) ||
          # last line of multiline selection
            (x_shifted_right >= ex && y_shifted_down > ey && end_y < sy) ||
            # middle line (all selected)
            (y > ey && y + height < sy))) ||
        # single line selection
        ((rect.includes_y?(sy) && rect.includes_y?(ey)) &&
          ((left && x_shifted_right < sx && x_shifted_right > ex) || (right && x_shifted_right > sx && x_shifted_right < ex)))
      )

      a
    end
  end
end
module Hokusai::Util
  class PositionSelection
    attr_accessor :positions, :cursor_index, :direction, :active

    def initialize
      @cursor_index = nil
      @positions = []
      @direction = :right
      @active = false
    end

    def move(to, selecting)
      self.active = selecting
  
      return if cursor_index.nil?

      # puts ["before", to, cursor_index, positions].inspect
      
      case to
      when :right
        self.cursor_index += 1
        if selecting && !positions.empty? && cursor_index <= positions.last
          positions.shift
        elsif selecting
          positions << cursor_index 
        end

      when :left
        if selecting && !positions.empty? && cursor_index >= positions.last
          positions.pop
        elsif selecting
          positions.unshift cursor_index
        end
  
        self.cursor_index -= 1 unless cursor_index == -1
      end
    end

    def active?
      @active
    end

    def left?
      direction == :left
    end

    def right?
      direction == :right
    end

    def clear
      self.cursor_index = nil
      positions.clear
    end

    def selected(index)
      active && (positions.first..positions.last).include?(index)
    end

    def select(range)
      self.positions = range.to_a
    end
  end
end

module Hokusai::Util
  class SelectionNew
    attr_reader :geom, :pos
    attr_accessor :type, :offset_y, :diff, :cursor

    def initialize
      @geom = GeometrySelection.new(self)
      @pos = PositionSelection.new
      @type = :geom
      @offset_y = 0.0
      @diff = 0.0
      @cursor = nil
    end

    def clear
      pos.clear
      geom.clear
    end

    def cursor
      geom.cursor
    end

    def geom!
      pos.clear
      pos.cursor_index = nil

      self.type = :geom
    end

    def pos!
      geom.clear

      self.type = :pos
    end

    def geom?
      type == :geom
    end

    def pos?
      type == :pos
    end

    def left?
      geom? ? geom.left? : pos.left?
    end

    def right?
      geom? ? geom.right? : pos.right?
    end

    def up?
      geom? && geom.up?
    end

    def down?
      geom? && geom.down?
    end

    def selecting?
      !(geom.type == :none && geom.click_pos.nil?)
    end

    # should we show the cursor?
    def active?
      !cursor.nil?
    end
  end
end

class Hokusai::Blocks::Text < Hokusai::Block
  template <<~EOF
  [template]
    empty {
      @keypress="check_copy"
    }
  EOF

  uses(empty: Hokusai::Blocks::Empty)

  computed! :content
  computed :background, default: [255, 255, 255], convert: Hokusai::Color
  computed :color, default: [222,222,222], convert: Hokusai::Color
  computed :selection_color, default: [43, 63, 61], convert: Hokusai::Color
  computed :selection_color_to, default: [0, 33, 233], convert: Hokusai::Color
  computed :animate_selection, default: false
  computed :padding, default: [20.0, 20.0, 20.0, 20.0], convert: Hokusai::Padding
  computed :font, default: nil
  computed :size, default: 15, convert: proc(&:to_i)
  computed :copy_text, default: false

  inject :panel_top
  inject :panel_height
  inject :panel_content_height
  inject :panel_offset
  inject :selection

  attr_accessor :copying, :copy_buffer, :measure_map, :last_content, :breaked, :render_height, :last_size, :last_y,
                :heights_loaded

  def on_mounted
    @copying = false
    @last_content = nil
    @last_size = nil
    @last_y = nil
    @heights_loaded = false
    @copy_buffer = ""
    @measure_map = nil
    @render_height = 0.0
    @breaked = false

    @progress = 0
    @back = false
  end

  def check_copy(event)
    if (event.ctrl || event.super) && event.symbol == :c
      self.copying = true
    end
  end

  def user_font
     font ? Hokusai.fonts.get(font) : Hokusai.fonts.active
  end

  def wrap_cache(canvas, force = false)

    should_splice = last_content != content && !last_content.nil?

    return @wrap_cache unless force || should_splice || !heights_loaded || breaked || @wrap_cache.nil?

    # if there's no cache, new / wrap
    # if the heights aren't loaded - new / wrap
    # if the content changed - use / splice
    # if forced / resized - new / wrap
    if force || !heights_loaded || breaked || @wrap_cache.nil?
      @wrap_cache = Hokusai::Util::WrapCache.new
    end

    self.breaked = false

    # for one big text, we want to use panel_top because canvas.y get's fucked on scroll
    # for looped items, we wawnt to use canvas.y    
    # puts ["canvas.y stream", canvas.y, panel_offset].inspect
    stream = Hokusai::Util::WrapStream.new(width(canvas), canvas.x, canvas.y + (panel_offset || 0)) do |string, extra|
      if w = user_font.measure_char(string, size)
        [w, size]
      else
        [user_font.measure(string, size).first, size]
      end
    end

    if should_splice
      stream.y = @wrap_cache.splice(stream, last_content, content)
    else
      stream.on_text do |wrapped|
        @wrap_cache << wrapped
      end

      stream.wrap(content, nil)
    end

    stream.flush
    self.render_height = stream.y

    if !last_y.nil?
      self.heights_loaded = true
    end

    self.last_y = canvas.y
    self.last_content = content.dup
    self.last_size = size

    @wrap_cache
  end

  def on_resize(canvas)
    self.breaked = true
  end

  def width(canvas)
    canvas.width - padding.width
  end

  def should_refresh(canvas)
    if breaked || last_size != size || (!heights_loaded)
      return true
    end

    false
  end

  # A fragment shader to rotate tint on asteroids
  def fshader
    <<-EOF
    #version 330
    in vec4 fragColor;
    in vec2 fragTexCoord;
    out vec4 finalColor;
    uniform sampler2D texture0;
    uniform vec4 from;
    uniform vec4 to;
    uniform float progress;

    void main() {
      vec4 texelColor = texture(texture0, fragTexCoord) * fragColor;

      finalColor.a = texelColor.a;
      finalColor.rgb = mix(from, to, progress).rgb;
    }
    EOF
  end

  def render(canvas)
    poffset = panel_offset || canvas.y
    pheight = panel_height || canvas.height
    pcheight = panel_content_height ||= canvas.height
    pptop = panel_top.nil? ? canvas.y : panel_top - canvas.y
    ptop = canvas.y + poffset

    cache = wrap_cache(canvas, should_refresh(canvas))
    diff = 0.0

    if selection
      selection.offset_y = poffset if selection.geom.active?
      diff = selection.offset_y - poffset
      selection.diff = diff
    end

    draw do
      tokens = cache.tokens_for(Hokusai::Canvas.new(canvas.width, pheight, canvas.x + padding.left, poffset))
      pad = Hokusai::Padding.new(padding.top, 0.0, 0.0, padding.left)

      if selection && animate_selection
        shader_begin do |command|
          command.fragment_shader = fshader
          command.uniforms = {
            "from" => [selection_color.to_shader_value, HP_SHADER_UNIFORM_VEC4], 
            "to" => [selection_color_to.to_shader_value, HP_SHADER_UNIFORM_VEC4],
            "progress" => [@progress, HP_SHADER_UNIFORM_FLOAT]
          }
        end
      end

      copied = cache.selected_area_for_tokens(tokens, selection, copy: copying || copy_text, padding: pad) do |rect|
        rect(rect.x, rect.y + diff, rect.width, rect.height) do |command|
          command.color = selection_color
        end
      end

      emit("selected", copied) unless copied.nil?

      if copying
        Hokusai.copy(copied.copy)
        self.copying = false
      end

      if copy_text
        emit("copy", copied)
      end

      if selection && animate_selection
        shader_end
      end

      tokens.each do |wrapped|
        # handle selection
        rect = Hokusai::Rect.new(wrapped.x + pad.left, (wrapped.y - (panel_offset || 0.0)) + padding.top, wrapped.width, wrapped.height)
        # draw text
        text(wrapped.text, rect.x, rect.y) do |command|
          command.color = color
          command.size = size
          if font
            command.font = Hokusai.fonts.get(font)
          end
        end
      end
    end

    node.meta.set_prop(:height, render_height)
    emit("height_updated", render_height)

    if @back
      @progress -= 0.02
    else
      @progress += 0.02
    end

    if @progress >= 1 && !@back
      @back = true
    elsif @progress <= 0 && @back
      @progress = 0
      @back = false
    end

    yield canvas
  end
end


class Hokusai::Blocks::Input < Hokusai::Block
  template <<~EOF
  [template]
    panel {
      @click="start_selection"
      @hover="update_selection"
      :autoclip="true"
  }
      text {
        :content="model"
        :size="size"
        :padding="padding"
        :selection_color="text_selection_color"
        :selection_color_to="text_selection_color_to"
        :animate_selection="animate_selection"
        @selected="handle_selection"
        @keypress="handle_keypress"
        @click="update_click_position"
      }
      cursor {
        height="0"
        :color="cursor_color"
        :x="cursor_x"
        :y="cursor_y"
        :cursor_height="cursor_height"
        :show="cursor_show"
      }
  EOF

  uses(
    panel: Hokusai::Blocks::Panel,
    cursor: Hokusai::Blocks::Cursor,
    selectable: Hokusai::Blocks::Selectable,
    text: Hokusai::Blocks::Text,
  )

  computed! :model

  computed :text_color, default: [33,33,33], convert: Hokusai::Color
  computed :text_selection_color, default: [233,233,233], convert: Hokusai::Color
  computed :text_selection_color_to, default: [0, 33, 233], convert: Hokusai::Color
  computed :animate_selection, default: false
  computed :cursor_color, default: [244,22,22], convert: Hokusai::Color
  computed :growable, default: false
  computed :size, default: 34, convert: proc(&:to_i)
  computed :padding, default: Hokusai::Padding.new(20.0, 20.0, 20.0, 20.0), convert: Hokusai::Padding

  attr_reader :selection
  attr_accessor :content, :buffer, :positions

  provide :selection, :selection

  def initialize(**args)
    super

    @buffer = ""
    @cursor = nil
    @selection = Hokusai::Util::SelectionNew.new
  end

  def update_click_position(event)
    selection.geom!
    selection.geom.set_click_pos(event.pos.x, event.pos.y)
  end

  def update_height(value)
    # node.meta.set_prop(:height, value)

    # emit("height_updated", value)
  end

  def handle_selection(copy)
    # puts [copy.inspect]
    # return if copy.nil?

    # @cursor = copy.cursor
  end

  def increment_cursor(selecting)
    selection.pos!

    selection.pos.move :right, selecting
  end

  def decrement_cursor(selecting)
    selection.pos!

    selection.pos.move :left, selecting
  end

  def handle_keypress(event)
    range = (selection.pos.positions.first..selection.pos.positions.last)

    if event.printable? && !event.super && !event.ctrl
      if selection.pos.positions.size > 0
        model[range] = event.char
        selection.pos.positions = []
        selection.geom.clear
        selection.pos.cursor_index = range.begin + 1
        # increment_cursor(false)
      elsif selection.pos.cursor_index
        model.insert(selection.pos.cursor_index + 1, event.char)
        increment_cursor(false)
      end
    elsif event.symbol == :backspace
      if selection.pos.positions.size > 0

        model[range] = ""
        selection.pos.positions = []
        selection.geom.clear
        selection.pos.cursor_index = range.begin + 1

        decrement_cursor(false) if selection.pos.cursor_index >= model.size

      elsif selection.pos.cursor_index
        model[selection.pos.cursor_index] = ""
        decrement_cursor(false)
      end
    elsif event.symbol == :right && selection.pos.cursor_index < model.size - 1
      increment_cursor(event.shift)
    elsif event.symbol == :left
      decrement_cursor(event.shift)
    end

    # puts ["model", model, selection.pos.cursor_index].inspect
  end

  # selection methods
  def start_selection(event)
    if event.left.down && !selection.geom.active?
      selection.pos.cursor_index = nil
      selection.geom!

      selection.geom.clear
      selection.geom.start(event.pos.x, event.pos.y)
    end
  end

  def update_selection(event)
    return unless selection.geom.active?

    if event.left.up
      selection.geom.freeze!
    elsif event.left.down
      selection.geom.stop(event.pos.x, event.pos.y)
    end
  end

  def cursor_x
    cursor(0)
  end

  def cursor_y
    cursor(1)
  end

  def cursor_height
    cursor(3)
  end

  def cursor_show
    !selection.cursor.nil?
  end

  def cursor(index)
    return if selection.cursor.nil?
    
    selection.cursor[index]
  end
end

class Hokusai::Blocks::Variable < Hokusai::Block
  template <<~EOF
  [template]
    empty
  EOF

  uses(empty: Hokusai::Blocks::Empty)

  computed! :script

  def after_updated
    if @last_height != children[0].node.meta.get_prop(:height)
      @last_height = children[0].node.meta.get_prop(:height)

      node.meta.set_prop(:height, @last_height)
      emit("height_updated", @last_height)
    end
  end

  def on_mounted
    klass = eval(script)

    raise Hokusai::Error.new("Class #{klass} is not a Hokusai::Block") unless klass.ancestors.include?(Hokusai::Block)

    node.meta.set_child(0, klass.mount)
  end

  def render(canvas)
    if Hokusai.can_render(canvas)
      yield canvas
    end
  end
end
module Hokusai::Blocks::Titlebar
  class OSX < Hokusai::Block
    GREEN = [38, 200, 75]
    YELLOW = [253, 189, 61]
    RED = [255, 92, 87]
    DEFAULT = [133, 133, 133]
    DRAG = [46,49,63]
    style <<~EOF
    [style]
    buttonStyle {
      cursor: "pointer";
    }
    EOF

    template <<-EOF
    [template]
      hblock {
        :background="get_background"
        :outline="outline"
        :outline_color="outline_color"
        :rounding="rounding"
        @mousedown="handle_move_start"
        @mousemove="handle_move"
        @hover="set_hover"
        @mouseout="clear_hover"
      }
        vblock { width="4" }
          empty
        vblock { width="60" }
          hblock 
            circle { ...buttonStyle @click="close" @hover="hover_red" @mouseout="blur_red" :radius="radius" :color="red" }
            circle { ...buttonStyle @click="minimize" @hover="hover_yellow" @mouseout="blur_yellow" :radius="radius" :color="yellow" }
            circle { ...buttonStyle @click="maximize" @hover="hover_green" @mouseout="blur_green" :radius="radius" :color="green" }
        vblock
          hblock
            slot
    EOF

    computed :rounding, default: 0.0, convert: proc(&:to_f)
    computed :outline, default: nil
    computed :outline_color, default: nil
    computed :unhovered_color, default: DEFAULT, convert: Hokusai::Color
    computed :radius, default: 6.0, convert: proc(&:to_f)
    computed :background, default: [22, 22, 22], convert: Hokusai::Color
    computed :background_drag, default: nil


    uses(
      circle: Hokusai::Blocks::Circle,
      vblock: Hokusai::Blocks::Vblock,
      hblock: Hokusai::Blocks::Hblock,
      empty: Hokusai::Blocks::Empty
    )

    attr_accessor :moving, :last_event, :hovering, :maximized

    def get_background
      moving ? background_drag : background
    end

    def handle_move_start(event)
      self.last_event = [event.pos.x, event.pos.y] unless moving
      self.moving = true
    end

    def handle_move(event)
      if moving && event.left.down
        x = event.pos.x - last_event[0]
        y = event.pos.y - last_event[1]

        Hokusai.set_window_position([x, y])
      else
        self.moving = false
      end
    end

    def set_hover(_)
      self.hovering = true
    end

    def clear_hover(_)
      self.hovering = false
    end

    def close(_)
      Hokusai.close_window
    end

    def minimize(_)
      Hokusai.minimize_window
    end

    def maximize(_)
      if maximized
        Hokusai.restore_window
        self.maximized = false
      else
        Hokusai.maximize_window
        self.maximized = true
      end
    end

    def blur_red(_)
      @hovered_red = false
    end

    def blur_yellow(_)
      @hovered_yellow = false
    end

    def blur_green(_)
      @hovered_green = false
    end

    def hover_red(_)
      @hovered_red = true
    end

    def hover_yellow(_)
      @hovered_yellow = true
    end

    def hover_green(_)
      @hovered_green = true
    end

    def red
      @hovered_red ? RED : unhovered_color
    end

    def yellow
      @hovered_yellow ? YELLOW : unhovered_color
    end

    def green
      @hovered_green ? GREEN : unhovered_color
    end

    def initialize(**args)
      super
      @hovered_red = false
      @hovered_yellow = false
      @hovered_green = false
      @moving = false
      @hovering = false
      @last_event = nil
      @maximized = false
    end
  end
end
class Hokusai::Blocks::Modal < Hokusai::Block
  style <<~EOF
  [style]
  closeButtonStyle {
    width: 40;
    height: 40;
    cursor: "pointer";
    padding: padding(10.0, 10.0, 10.0, 0.0)
  }
  EOF

  template <<~EOF
  [template]
    hblock
      empty
      empty
      image {
        :source="close_icon"
        ...closeButtonStyle
        @click="emit_close"

      }
    hblock
      empty
      slot
      empty
    hblock
      empty
  EOF

  uses(
    vblock: Hokusai::Blocks::Vblock,
    hblock: Hokusai::Blocks::Hblock,
    empty: Hokusai::Blocks::Empty,
    image: Hokusai::Blocks::Image
  )

  computed :active, default: false
  computed :background, default: [0, 0, 0, 200], convert: Hokusai::Color

  def emit_close(event)
    emit("close")
  end

  def on_mounted
    node.meta.set_prop(:z, 1)
    node.meta.set_prop(:ztarget, "root")
  end

  def render(canvas)
    return unless active

    draw do
      rect(canvas.x, canvas.y, canvas.width, canvas.height) do |command|
        command.color = background
      end
    end

    yield canvas
  end
end

class Hokusai::Blocks::Texture < Hokusai::Block
  template <<~EOF
  [template]
    virtual
  EOF

  computed :width, default: nil, convert: proc(&:to_i)
  computed :height, default: nil, convert: proc(&:to_i)
  computed :x, default: nil
  computed :y, default: nil
  computed :rotation, default: nil
  computed :scale, default: 100.0
  
  def render(canvas)
    draw do
      texture(x || canvas.x, y || canvas.y, width || canvas.width, height || canvas.height) do |command|
        command.rotation = rotation if rotation
        command.scale = scale
      end
    end
  end
end

class Hokusai::Blocks::ShaderBegin < Hokusai::Block
  template <<~EOF
  [template]
    slot
  EOF

  computed :fragment_shader, default: nil
  computed :vertex_shader, default: nil
  computed :uniforms, default: {}

  def render(canvas)
    draw do
      shader_begin do |command|
        command.vertex_shader = vertex_shader
        command.fragment_shader = fragment_shader
        command.uniforms = uniforms
      end
    end

    yield canvas
  end
end
class Hokusai::Blocks::ShaderEnd < Hokusai::Block
  template <<~EOF
  [template]
    virtual
  EOF

  def render(canvas)
    draw do
      shader_end
    end
  end
end

class PickerCircle < Hokusai::Block
  template <<-EOF
  [template]
    virtual
  EOF

  computed! :x
  computed! :y
  computed! :color
  computed! :radius

  def on_mounted
    node.meta.set_prop(:z, 3);
    node.meta.set_prop(:ztarget, "root")
  end

  def render(canvas)
    draw do
      circle(x, y - radius, radius + 2.0) do |command|
        command.color = Hokusai::Color.new(255, 255, 255)
      end
      circle(x, y - radius, radius) do |command|
        command.color = color
      end

      text("rgb(#{color.r.round(0)},#{color.g.round(0)},#{color.b.round(0)})", x - 90.0, y + radius) do |command|
        command.size = 15
        command.color = Hokusai::Color.new(255, 255, 255)
      end
    end
  end
end

class Hokusai::Blocks::ColorPicker < Hokusai::Block
  template <<~EOF
  [template]
    hblock { }
      vblock { 
        @mousedown="start_selection"
        @mousemove="update_selection"
      }
        shader_begin {
          :fragment_shader="picker_shader"
          :uniforms="values"
        }
          texture
          shader_end { :height="0.0" :width="0.0" }
      vblock {
        width="32"
        cursor="crosshair"
      }
        shader_begin { 
          @mousedown="save_position"
          :fragment_shader="hue_shader"
          :uniforms="values"
        }
          texture
          shader_end { :height="0.0" :width="0.0"}
      vblock { :z="3" ztarget="root"}
        [if="picking"]
          pickercircle {
            :radius="10.0"
            :x="pickerx"
            :y="pickery"
            :color="color"
          }
  EOF

  uses(
    rect: Hokusai::Blocks::Rect,
    empty: Hokusai::Blocks::Empty,
    image: Hokusai::Blocks::Image,
    shader_begin: Hokusai::Blocks::ShaderBegin, 
    shader_end: Hokusai::Blocks::ShaderEnd, 
    texture: Hokusai::Blocks::Texture,
    hblock: Hokusai::Blocks::Hblock,
    vblock: Hokusai::Blocks::Vblock,
    pickercircle: PickerCircle
  )

  attr_accessor :position, :top, :left, :height, :width, :selecting, :selection,
                :brightness, :saturation, :pickerx, :pickery
  

  def start_selection(event)
    if event.left.down
      self.selecting = true
    end
  end

  def picking
    selecting && pickerx && pickery
  end

  K1 = 0.206;
  K2 = 0.03;
  K3 = (1.0 + K1) / (1.0 + K2);

  def toe_inv(x)
    (x * x + K1 * x) / (K3 * (x + K2))
  end

  def compute_max_saturation(a, b)
    if -1.88170328 * a - 0.80936493 * b > 1.0
      k0 = +1.19086277
      k1 = +1.76576728
      k2 = +0.59662641
      k3 = +0.75515197
      k4 = +0.56771245
      wl = +4.0767416621
      wm = -3.3077115913
      ws = +0.2309699292
    elsif 1.81444104 * a - 1.19445276 * b > 1.0
      k0 = +0.73956515
      k1 = -0.45954404
      k2 = +0.08285427
      k3 = +0.12541070
      k4 = +0.14503204
      wl = -1.2684380046
      wm = +2.6097574011
      ws = -0.3413193965
    else
      k0 = +1.35733652
      k1 = -0.00915799
      k2 = -1.15130210
      k3 = -0.50559606
      k4 = +0.00692167
      wl = -0.0041960863
      wm = -0.7034186147
      ws = +1.7076147010
    end

    sat = k0 + k1 * a + k2 * b + k3 * a * a + k4 * a * b

    kl = +0.3963377774 * a + 0.2158037573 * b
    km = -0.1055613458 * a - 0.0638541728 * b
    ks = -0.0894841775 * a - 1.2914855480 * b

    l_ = 1.0 + sat * kl
    m_ = 1.0 + sat * km
    s_ = 1.0 + sat * ks

    l = l_ ** 3
    m = m_ ** 3
    s = s_ ** 3

    lds = 3.0 * kl * l_ * l_
    mds = 3.0 * km * m_ * m_
    sds = 3.0 * ks * s_ * s_

    lds2 = 6.0 * kl ** 2 * l_
    mds2 = 6.0 * km ** 2 * m_
    sds2 = 6.0 * ks ** 2 * s_


    f = wl * l + wm * m + ws * s
    f1 = wl * lds + wm * mds + ws * sds
    f2 = wl * lds2 + wm * mds2 + ws * sds2

    sat = sat - (f * f1) / (f1 ** 2 - 0.5 * f * f2)

    sat
  end

  def find_cusp(a, b)
    s_cusp = compute_max_saturation(a, b)

    rgb = oklab_to_linear_srgb(1.0, s_cusp * a, s_cusp * b)
    l_cusp = cbrt(1.0 / rgb.max)
    c_cusp = l_cusp * s_cusp

    [l_cusp, c_cusp]
  end

  def to_st(cusp)
    l, c = cusp
    [c / l, c / (1.0 - l)]
  end
  
  def oklab_to_linear_srgb(*lab)
    r, g, b = lab
    
    l_ = r + 0.3963377774 * g + 0.2158037573 * b
    m_ = r - 0.1055613458 * g - 0.0638541728 * b
    s_ = r - 0.0894841775 * g - 1.2914855480 * b

    l = l_ * l_ * l_
    m = m_ * m_ * m_
    s = s_ * s_ * s_

    [
      4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
      -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
      -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s
    ]
  end

  def cbrt(x)
    (x <=> 0) * (x.abs ** (1.0 / 3.0))
  end

  def oklab
    h = hue
    s = saturation
    v = brightness

    tau = Math::PI * 2.0

      _a = Math.cos(tau * h)
      _b = Math.sin(tau * h)

      s_max, t_max = to_st(find_cusp(_a, _b))

      so = 0.5
      k = 1.0 - so / s_max

      lv = 1.0 - (s * so) / (so + t_max - t_max * k * s)
      cv = (s * t_max * so) / (so + t_max - t_max * k * s)

      l = v * lv
      c = v * cv

      lvt = toe_inv(lv)
      cvt = (cv * lvt) / lv

      l_new = toe_inv(l)
      c = (c * l_new) / l
      l = l_new

      rs, gs, bs = oklab_to_linear_srgb(lvt, _a * cvt, _b * cvt)
      scale_l = cbrt(1.0 / [rs, gs, bs, 0.0].max)

      l = l * scale_l
      c = c * scale_l

      a = c * _a
      b = c * _b


      l, a, b = oklab_to_linear_srgb(l, a, b)
    # end
    [srgb_transfer_function(l), srgb_transfer_function(a), srgb_transfer_function(b)]
  end

  def srgb_transfer_function(a)
    0.0031308 >= a ? 12.92 * a : 1.055 * (a ** 0.4166666666666667) - 0.055;
  end

  def color(alpha = 255)
    return if brightness.nil? || saturation.nil?
    r, g, b = oklab

    return Hokusai::Color.new(0, 0, 0, 0) if r.nan? || g.nan? || b.nan?

    return Hokusai::Color.new(r * 255, g * 255, b * 255)
  end

  def update_selection(event)
    if event.left.down && selecting
      # Hokusai.set_mouse_cursor(:none)
      w = width - 32.0
      posx = event.pos.x

      b = ((posx - left) / w)
      self.pickerx = posx
      unless b > 1.0 || b < 0.0
        self.saturation = b
      end

      posy = event.pos.y
      t = ((posy - top) / height)
      self.pickery = posy
      unless t > 1.0 || t < 0.0
        self.brightness = 1 - t 
      end

      emit("change", color)
    else
      # Hokusai.set_mouse_cursor(:pointer)

      self.selecting = false
    end
  end

  def save_position(event)
    self.position = [event.pos.x, event.pos.y]
  end

  def hue
    return 0.0 if position.nil?

    pos = (position[1] - (top || 0)) 
    y = (pos / height)
  end

  def values
   return {} unless position

   return {} if hue > 1 || hue < 0
  
   {
    "uHue" => [hue, HP_SHADER_UNIFORM_FLOAT]
   }
  end

  HUE_SHADER = <<~EOF
  #version 330

  in vec2 fragTexCoord;
  in vec4 fragColor;

  out vec4 finalColor;

  #define PI 3.1415926535897932384626433832795
  #define PICKER_SIZE_INV (1.0 / 255.0)

  float hsluv_fromLinear(float c) {
      return c <= 0.0031308 ? 12.92 * c : 1.055 * pow(c, 1.0 / 2.4) - 0.055;
  }
  vec3 hsluv_fromLinear(vec3 c) {
      return vec3( hsluv_fromLinear(c.r), hsluv_fromLinear(c.g), hsluv_fromLinear(c.b) );
  }

  vec3 xyzToRgb(vec3 tuple) {
      const mat3 m = mat3( 
          3.2409699419045214  ,-1.5373831775700935 ,-0.49861076029300328 ,
        -0.96924363628087983 , 1.8759675015077207 , 0.041555057407175613,
          0.055630079696993609,-0.20397695888897657, 1.0569715142428786  );
      
      return hsluv_fromLinear(tuple*m);
  }

  float hsluv_lToY(float L) {
      return L <= 8.0 ? L / 903.2962962962963 : pow((L + 16.0) / 116.0, 3.0);
  }

  vec3 luvToXyz(vec3 tuple) {
      float L = tuple.x;

      float U = tuple.y / (13.0 * L) + 0.19783000664283681;
      float V = tuple.z / (13.0 * L) + 0.468319994938791;

      float Y = hsluv_lToY(L);
      float X = 2.25 * U * Y / V;
      float Z = (3./V - 5.)*Y - (X/3.);

      return vec3(X, Y, Z);
  }

  vec3 lchToLuv(vec3 tuple) {
      float hrad = radians(tuple.b);
      return vec3(
          tuple.r,
          cos(hrad) * tuple.g,
          sin(hrad) * tuple.g
      );
  }

  vec3 lchToRgb(vec3 tuple) {
      return xyzToRgb(luvToXyz(lchToLuv(tuple)));
  }

  vec3 hsluv_lengthOfRayUntilIntersect(float theta, vec3 x, vec3 y) {
      vec3 len = y / (sin(theta) - x * cos(theta));
      if (len.r < 0.0) {len.r=1000.0;}
      if (len.g < 0.0) {len.g=1000.0;}
      if (len.b < 0.0) {len.b=1000.0;}
      return len;
  }

  float hsluv_maxChromaForLH(float L, float H) {
      float hrad = radians(H);

      mat3 m2 = mat3(
          3.2409699419045214  ,-0.96924363628087983 , 0.055630079696993609,
          -1.5373831775700935  , 1.8759675015077207  ,-0.20397695888897657 ,
          -0.49861076029300328 , 0.041555057407175613, 1.0569715142428786  
      );
      float sub1 = pow(L + 16.0, 3.0) / 1560896.0;
      float sub2 = sub1 > 0.0088564516790356308 ? sub1 : L / 903.2962962962963;

      vec3 top1   = (284517.0 * m2[0] - 94839.0  * m2[2]) * sub2;
      vec3 bottom = (632260.0 * m2[2] - 126452.0 * m2[1]) * sub2;
      vec3 top2   = (838422.0 * m2[2] + 769860.0 * m2[1] + 731718.0 * m2[0]) * L * sub2;

      vec3 bound0x = top1 / bottom;
      vec3 bound0y = top2 / bottom;

      vec3 bound1x =              top1 / (bottom+126452.0);
      vec3 bound1y = (top2-769860.0*L) / (bottom+126452.0);

      vec3 lengths0 = hsluv_lengthOfRayUntilIntersect(hrad, bound0x, bound0y );
      vec3 lengths1 = hsluv_lengthOfRayUntilIntersect(hrad, bound1x, bound1y );

      return  min(lengths0.r,
              min(lengths1.r,
              min(lengths0.g,
              min(lengths1.g,
              min(lengths0.b,
                  lengths1.b)))));
  }

  vec3 hsluvToLch(vec3 tuple) {
      tuple.g *= hsluv_maxChromaForLH(tuple.b, tuple.r) * .01;
      return tuple.bgr;
  }

  vec3 hsluvToRgb(vec3 tuple) {
      return lchToRgb(hsluvToLch(tuple));
  }
  vec3 hsluvToRgb(float x, float y, float z) {return hsluvToRgb( vec3(x,y,z) );}

  void main() {
    float a_ = cos(2 * PI * fragTexCoord.y);
    float b_ = sin(2 * PI * fragTexCoord.y);

    float h = fragTexCoord.y;
    float s = 0.9;
    float l = 0.65 + 0.20 * b_ - 0.09 * a_;

    vec3 col = hsluvToRgb(h * 360, s * 100, l * 100);
    finalColor = vec4(col, 1.0);
  }
  EOF

  PICKER_SHADER = <<~EOF
  #version 330

  in vec2 fragTexCoord;
  in vec4 fragColor;

  uniform float uHue;

  out vec4 finalColor;

  #define M_PI 3.1415926535897932384626433832795

  float cbrt( float x ) {
      return sign(x)*pow(abs(x),1.0f/3.0f);
  }

  float srgb_transfer_function(float a) {
    return .0031308f >= a ? 12.92f * a : 1.055f * pow(a, .4166666666666667f) - .055f;
  }

  float srgb_transfer_function_inv(float a) {
    return .04045f < a ? pow((a + .055f) / 1.055f, 2.4f) : a / 12.92f;
  }

  vec3 linear_srgb_to_oklab(vec3 c) {
    float l = 0.4122214708f * c.r + 0.5363325363f * c.g + 0.0514459929f * c.b;
    float m = 0.2119034982f * c.r + 0.6806995451f * c.g + 0.1073969566f * c.b;
    float s = 0.0883024619f * c.r + 0.2817188376f * c.g + 0.6299787005f * c.b;

    float l_ = cbrt(l);
    float m_ = cbrt(m);
    float s_ = cbrt(s);

    return vec3(
      0.2104542553f * l_ + 0.7936177850f * m_ - 0.0040720468f * s_,
      1.9779984951f * l_ - 2.4285922050f * m_ + 0.4505937099f * s_,
      0.0259040371f * l_ + 0.7827717662f * m_ - 0.8086757660f * s_
    );
  }

  vec3 oklab_to_linear_srgb(vec3 c) {
    float l_ = c.x + 0.3963377774f * c.y + 0.2158037573f * c.z;
    float m_ = c.x - 0.1055613458f * c.y - 0.0638541728f * c.z;
    float s_ = c.x - 0.0894841775f * c.y - 1.2914855480f * c.z;

    float l = l_ * l_ * l_;
    float m = m_ * m_ * m_;
    float s = s_ * s_ * s_;

    return vec3(
      +4.0767416621f * l - 3.3077115913f * m + 0.2309699292f * s,
      -1.2684380046f * l + 2.6097574011f * m - 0.3413193965f * s,
      -0.0041960863f * l - 0.7034186147f * m + 1.7076147010f * s
    );
  }

  // Finds the maximum saturation possible for a given hue that fits in sRGB
  // Saturation here is defined as S = C/L
  // a and b must be normalized so a^2 + b^2 == 1
  float compute_max_saturation(float a, float b) {
    // Max saturation will be when one of r, g or b goes below zero.

    // Select different coefficients depending on which component goes below zero first
    float k0, k1, k2, k3, k4, wl, wm, ws;

    if (-1.88170328f * a - 0.80936493f * b > 1.f)
    {
      // Red component
      k0 = +1.19086277f; k1 = +1.76576728f; k2 = +0.59662641f; k3 = +0.75515197f; k4 = +0.56771245f;
      wl = +4.0767416621f; wm = -3.3077115913f; ws = +0.2309699292f;
    }
    else if (1.81444104f * a - 1.19445276f * b > 1.f)
    {
      // Green component
      k0 = +0.73956515f; k1 = -0.45954404f; k2 = +0.08285427f; k3 = +0.12541070f; k4 = +0.14503204f;
      wl = -1.2684380046f; wm = +2.6097574011f; ws = -0.3413193965f;
    }
    else
    {
      // Blue component
      k0 = +1.35733652f; k1 = -0.00915799f; k2 = -1.15130210f; k3 = -0.50559606f; k4 = +0.00692167f;
      wl = -0.0041960863f; wm = -0.7034186147f; ws = +1.7076147010f;
    }

    // Approximate max saturation using a polynomial:
    float S = k0 + k1 * a + k2 * b + k3 * a * a + k4 * a * b;

    // Do one step Halley's method to get closer
    // this gives an error less than 10e6, except for some blue hues where the dS/dh is close to infinite
    // this should be sufficient for most applications, otherwise do two/three steps 

    float k_l = +0.3963377774f * a + 0.2158037573f * b;
    float k_m = -0.1055613458f * a - 0.0638541728f * b;
    float k_s = -0.0894841775f * a - 1.2914855480f * b;

    {
      float l_ = 1.f + S * k_l;
      float m_ = 1.f + S * k_m;
      float s_ = 1.f + S * k_s;

      float l = l_ * l_ * l_;
      float m = m_ * m_ * m_;
      float s = s_ * s_ * s_;

      float l_dS = 3.f * k_l * l_ * l_;
      float m_dS = 3.f * k_m * m_ * m_;
      float s_dS = 3.f * k_s * s_ * s_;

      float l_dS2 = 6.f * k_l * k_l * l_;
      float m_dS2 = 6.f * k_m * k_m * m_;
      float s_dS2 = 6.f * k_s * k_s * s_;

      float f = wl * l + wm * m + ws * s;
      float f1 = wl * l_dS + wm * m_dS + ws * s_dS;
      float f2 = wl * l_dS2 + wm * m_dS2 + ws * s_dS2;

      S = S - f * f1 / (f1 * f1 - 0.5f * f * f2);
    }

    return S;
  }

  // finds L_cusp and C_cusp for a given hue
  // a and b must be normalized so a^2 + b^2 == 1
  vec2 find_cusp(float a, float b) {
    // First, find the maximum saturation (saturation S = C/L)
    float S_cusp = compute_max_saturation(a, b);

    // Convert to linear sRGB to find the first point where at least one of r,g or b >= 1:
    vec3 rgb_at_max = oklab_to_linear_srgb(vec3( 1, S_cusp * a, S_cusp * b ));
    float L_cusp = cbrt(1.f / max(max(rgb_at_max.r, rgb_at_max.g), rgb_at_max.b));
    float C_cusp = L_cusp * S_cusp;

    return vec2( L_cusp , C_cusp );
  }

  // Finds intersection of the line defined by 
  // L = L0 * (1 - t) + t * L1;
  // C = t * C1;
  // a and b must be normalized so a^2 + b^2 == 1
  float find_gamut_intersection(float a, float b, float L1, float C1, float L0, vec2 cusp) {
    // Find the intersection for upper and lower half seprately
    float t;
    if (((L1 - L0) * cusp.y - (cusp.x - L0) * C1) <= 0.f)
    {
      // Lower half

      t = cusp.y * L0 / (C1 * cusp.x + cusp.y * (L0 - L1));
    }
    else
    {
      // Upper half

      // First intersect with triangle
      t = cusp.y * (L0 - 1.f) / (C1 * (cusp.x - 1.f) + cusp.y * (L0 - L1));

      // Then one step Halley's method
      {
        float dL = L1 - L0;
        float dC = C1;

        float k_l = +0.3963377774f * a + 0.2158037573f * b;
        float k_m = -0.1055613458f * a - 0.0638541728f * b;
        float k_s = -0.0894841775f * a - 1.2914855480f * b;

        float l_dt = dL + dC * k_l;
        float m_dt = dL + dC * k_m;
        float s_dt = dL + dC * k_s;


        // If higher accuracy is required, 2 or 3 iterations of the following block can be used:
        {
          float L = L0 * (1.f - t) + t * L1;
          float C = t * C1;

          float l_ = L + C * k_l;
          float m_ = L + C * k_m;
          float s_ = L + C * k_s;

          float l = l_ * l_ * l_;
          float m = m_ * m_ * m_;
          float s = s_ * s_ * s_;

          float ldt = 3.f * l_dt * l_ * l_;
          float mdt = 3.f * m_dt * m_ * m_;
          float sdt = 3.f * s_dt * s_ * s_;

          float ldt2 = 6.f * l_dt * l_dt * l_;
          float mdt2 = 6.f * m_dt * m_dt * m_;
          float sdt2 = 6.f * s_dt * s_dt * s_;

          float r = 4.0767416621f * l - 3.3077115913f * m + 0.2309699292f * s - 1.f;
          float r1 = 4.0767416621f * ldt - 3.3077115913f * mdt + 0.2309699292f * sdt;
          float r2 = 4.0767416621f * ldt2 - 3.3077115913f * mdt2 + 0.2309699292f * sdt2;

          float u_r = r1 / (r1 * r1 - 0.5f * r * r2);
          float t_r = -r * u_r;

          float g = -1.2684380046f * l + 2.6097574011f * m - 0.3413193965f * s - 1.f;
          float g1 = -1.2684380046f * ldt + 2.6097574011f * mdt - 0.3413193965f * sdt;
          float g2 = -1.2684380046f * ldt2 + 2.6097574011f * mdt2 - 0.3413193965f * sdt2;

          float u_g = g1 / (g1 * g1 - 0.5f * g * g2);
          float t_g = -g * u_g;

          float b = -0.0041960863f * l - 0.7034186147f * m + 1.7076147010f * s - 1.f;
          float b1 = -0.0041960863f * ldt - 0.7034186147f * mdt + 1.7076147010f * sdt;
          float b2 = -0.0041960863f * ldt2 - 0.7034186147f * mdt2 + 1.7076147010f * sdt2;

          float u_b = b1 / (b1 * b1 - 0.5f * b * b2);
          float t_b = -b * u_b;

          t_r = u_r >= 0.f ? t_r : 10000.f;
          t_g = u_g >= 0.f ? t_g : 10000.f;
          t_b = u_b >= 0.f ? t_b : 10000.f;

          t += min(t_r, min(t_g, t_b));
        }
      }
    }

    return t;
  }

  float find_gamut_intersection(float a, float b, float L1, float C1, float L0) {
    // Find the cusp of the gamut triangle
    vec2 cusp = find_cusp(a, b);

    return find_gamut_intersection(a, b, L1, C1, L0, cusp);
  }

  vec3 gamut_clip_preserve_chroma(vec3 rgb) {
    if (rgb.r < 1.f && rgb.g < 1.f && rgb.b < 1.f && rgb.r > 0.f && rgb.g > 0.f && rgb.b > 0.f)
      return rgb;

    vec3 lab = linear_srgb_to_oklab(rgb);

    float L = lab.x;
    float eps = 0.00001f;
    float C = max(eps, sqrt(lab.y * lab.y + lab.z * lab.z));
    float a_ = lab.y / C;
    float b_ = lab.z / C;

    float L0 = clamp(L, 0.f, 1.f);

    float t = find_gamut_intersection(a_, b_, L, C, L0);
    float L_clipped = L0 * (1.f - t) + t * L;
    float C_clipped = t * C;

    return oklab_to_linear_srgb(vec3( L_clipped, C_clipped * a_, C_clipped * b_ ));
  }

  vec3 gamut_clip_project_to_0_5(vec3 rgb) {
    if (rgb.r < 1.f && rgb.g < 1.f && rgb.b < 1.f && rgb.r > 0.f && rgb.g > 0.f && rgb.b > 0.f)
      return rgb;

    vec3 lab = linear_srgb_to_oklab(rgb);

    float L = lab.x;
    float eps = 0.00001f;
    float C = max(eps, sqrt(lab.y * lab.y + lab.z * lab.z));
    float a_ = lab.y / C;
    float b_ = lab.z / C;

    float L0 = 0.5;

    float t = find_gamut_intersection(a_, b_, L, C, L0);
    float L_clipped = L0 * (1.f - t) + t * L;
    float C_clipped = t * C;

    return oklab_to_linear_srgb(vec3( L_clipped, C_clipped * a_, C_clipped * b_ ));
  }

  vec3 gamut_clip_project_to_L_cusp(vec3 rgb) {
    if (rgb.r < 1.f && rgb.g < 1.f && rgb.b < 1.f && rgb.r > 0.f && rgb.g > 0.f && rgb.b > 0.f)
      return rgb;

    vec3 lab = linear_srgb_to_oklab(rgb);

    float L = lab.x;
    float eps = 0.00001f;
    float C = max(eps, sqrt(lab.y * lab.y + lab.z * lab.z));
    float a_ = lab.y / C;
    float b_ = lab.z / C;

    // The cusp is computed here and in find_gamut_intersection, an optimized solution would only compute it once.
    vec2 cusp = find_cusp(a_, b_);

    float L0 = cusp.x;

    float t = find_gamut_intersection(a_, b_, L, C, L0);

    float L_clipped = L0 * (1.f - t) + t * L;
    float C_clipped = t * C;

    return oklab_to_linear_srgb(vec3( L_clipped, C_clipped * a_, C_clipped * b_ ));
  }

  vec3 gamut_clip_adaptive_L0_0_5(vec3 rgb, float alpha) {
    if (rgb.r < 1.f && rgb.g < 1.f && rgb.b < 1.f && rgb.r > 0.f && rgb.g > 0.f && rgb.b > 0.f)
      return rgb;

    vec3 lab = linear_srgb_to_oklab(rgb);

    float L = lab.x;
    float eps = 0.00001f;
    float C = max(eps, sqrt(lab.y * lab.y + lab.z * lab.z));
    float a_ = lab.y / C;
    float b_ = lab.z / C;

    float Ld = L - 0.5f;
    float e1 = 0.5f + abs(Ld) + alpha * C;
    float L0 = 0.5f * (1.f + sign(Ld) * (e1 - sqrt(e1 * e1 - 2.f * abs(Ld))));

    float t = find_gamut_intersection(a_, b_, L, C, L0);
    float L_clipped = L0 * (1.f - t) + t * L;
    float C_clipped = t * C;

    return oklab_to_linear_srgb(vec3( L_clipped, C_clipped * a_, C_clipped * b_ ));
  }

  vec3 gamut_clip_adaptive_L0_L_cusp(vec3 rgb, float alpha) {
    if (rgb.r < 1.f && rgb.g < 1.f && rgb.b < 1.f && rgb.r > 0.f && rgb.g > 0.f && rgb.b > 0.f)
      return rgb;

    vec3 lab = linear_srgb_to_oklab(rgb);

    float L = lab.x;
    float eps = 0.00001f;
    float C = max(eps, sqrt(lab.y * lab.y + lab.z * lab.z));
    float a_ = lab.y / C;
    float b_ = lab.z / C;

    // The cusp is computed here and in find_gamut_intersection, an optimized solution would only compute it once.
    vec2 cusp = find_cusp(a_, b_);

    float Ld = L - cusp.x;
    float k = 2.f * (Ld > 0.f ? 1.f - cusp.x : cusp.x);

    float e1 = 0.5f * k + abs(Ld) + alpha * C / k;
    float L0 = cusp.x + 0.5f * (sign(Ld) * (e1 - sqrt(e1 * e1 - 2.f * k * abs(Ld))));

    float t = find_gamut_intersection(a_, b_, L, C, L0);
    float L_clipped = L0 * (1.f - t) + t * L;
    float C_clipped = t * C;

    return oklab_to_linear_srgb(vec3( L_clipped, C_clipped * a_, C_clipped * b_ ));
  }

  float toe(float x) {
    float k_1 = 0.206f;
    float k_2 = 0.03f;
    float k_3 = (1.f + k_1) / (1.f + k_2);
    return 0.5f * (k_3 * x - k_1 + sqrt((k_3 * x - k_1) * (k_3 * x - k_1) + 4.f * k_2 * k_3 * x));
  }

  float toe_inv(float x) {
    float k_1 = 0.206f;
    float k_2 = 0.03f;
    float k_3 = (1.f + k_1) / (1.f + k_2);
    return (x * x + k_1 * x) / (k_3 * (x + k_2));
  }

  vec2 to_ST(vec2 cusp) {
    float L = cusp.x;
    float C = cusp.y;
    return vec2( C / L, C / (1.f - L) );
  }

  // Returns a smooth approximation of the location of the cusp
  // This polynomial was created by an optimization process
  // It has been designed so that S_mid < S_max and T_mid < T_max
  vec2 get_ST_mid(float a_, float b_) {
    float S = 0.11516993f + 1.f / (
      +7.44778970f + 4.15901240f * b_
      + a_ * (-2.19557347f + 1.75198401f * b_
        + a_ * (-2.13704948f - 10.02301043f * b_
          + a_ * (-4.24894561f + 5.38770819f * b_ + 4.69891013f * a_
            )))
      );

    float T = 0.11239642f + 1.f / (
      +1.61320320f - 0.68124379f * b_
      + a_ * (+0.40370612f + 0.90148123f * b_
        + a_ * (-0.27087943f + 0.61223990f * b_
          + a_ * (+0.00299215f - 0.45399568f * b_ - 0.14661872f * a_
            )))
      );

    return vec2( S, T );
  }

  vec3 get_Cs(float L, float a_, float b_) {
    vec2 cusp = find_cusp(a_, b_);

    float C_max = find_gamut_intersection(a_, b_, L, 1.f, L, cusp);
    vec2 ST_max = to_ST(cusp);
    
    // Scale factor to compensate for the curved part of gamut shape:
    float k = C_max / min((L * ST_max.x), (1.f - L) * ST_max.y);

    float C_mid;
    {
      vec2 ST_mid = get_ST_mid(a_, b_);

      // Use a soft minimum function, instead of a sharp triangle shape to get a smooth value for chroma.
      float C_a = L * ST_mid.x;
      float C_b = (1.f - L) * ST_mid.y;
      C_mid = 0.9f * k * sqrt(sqrt(1.f / (1.f / (C_a * C_a * C_a * C_a) + 1.f / (C_b * C_b * C_b * C_b))));
    }

    float C_0;
    {
      // for C_0, the shape is independent of hue, so vec2 are constant. Values picked to roughly be the average values of vec2.
      float C_a = L * 0.4f;
      float C_b = (1.f - L) * 0.8f;

      // Use a soft minimum function, instead of a sharp triangle shape to get a smooth value for chroma.
      C_0 = sqrt(1.f / (1.f / (C_a * C_a) + 1.f / (C_b * C_b)));
    }

    return vec3( C_0, C_mid, C_max );
  }

  vec3 okhsl_to_srgb(vec3 hsl) {
    float h = hsl.x;
    float s = hsl.y;
    float l = hsl.z;

    if (l == 1.0f)
    {
      return vec3( 1.f, 1.f, 1.f );
    }

    else if (l == 0.f)
    {
      return vec3( 0.f, 0.f, 0.f );
    }

    float a_ = cos(2.f * M_PI * h);
    float b_ = sin(2.f * M_PI * h);
    float L = toe_inv(l);

    vec3 cs = get_Cs(L, a_, b_);
    float C_0 = cs.x;
    float C_mid = cs.y;
    float C_max = cs.z;

    float mid = 0.8f;
    float mid_inv = 1.25f;

    float C, t, k_0, k_1, k_2;

    if (s < mid)
    {
      t = mid_inv * s;

      k_1 = mid * C_0;
      k_2 = (1.f - k_1 / C_mid);

      C = t * k_1 / (1.f - k_2 * t);
    }
    else
    {
      t = (s - mid)/ (1.f - mid);

      k_0 = C_mid;
      k_1 = (1.f - mid) * C_mid * C_mid * mid_inv * mid_inv / C_0;
      k_2 = (1.f - (k_1) / (C_max - C_mid));

      C = k_0 + t * k_1 / (1.f - k_2 * t);
    }

    vec3 rgb = oklab_to_linear_srgb(vec3( L, C * a_, C * b_ ));
    return vec3(
      srgb_transfer_function(rgb.r),
      srgb_transfer_function(rgb.g),
      srgb_transfer_function(rgb.b)
    );
  }

  vec3 srgb_to_okhsl(vec3 rgb) {
    vec3 lab = linear_srgb_to_oklab(vec3(
      srgb_transfer_function_inv(rgb.r),
      srgb_transfer_function_inv(rgb.g),
      srgb_transfer_function_inv(rgb.b)
      ));

    float C = sqrt(lab.y * lab.y + lab.z * lab.z);
    float a_ = lab.y / C;
    float b_ = lab.z / C;

    float L = lab.x;
    float h = 0.5f + 0.5f * atan(-lab.z, -lab.y) / M_PI;

    vec3 cs = get_Cs(L, a_, b_);
    float C_0 = cs.x;
    float C_mid = cs.y;
    float C_max = cs.z;

    // Inverse of the interpolation in okhsl_to_srgb:

    float mid = 0.8f;
    float mid_inv = 1.25f;

    float s;
    if (C < C_mid)
    {
      float k_1 = mid * C_0;
      float k_2 = (1.f - k_1 / C_mid);

      float t = C / (k_1 + k_2 * C);
      s = t * mid;
    }
    else
    {
      float k_0 = C_mid;
      float k_1 = (1.f - mid) * C_mid * C_mid * mid_inv * mid_inv / C_0;
      float k_2 = (1.f - (k_1) / (C_max - C_mid));

      float t = (C - k_0) / (k_1 + k_2 * (C - k_0));
      s = mid + (1.f - mid) * t;
    }

    float l = toe(L);
    return vec3( h, s, l );
  }


  vec3 okhsv_to_srgb(vec3 hsv) {
    float h = hsv.x;
    float s = hsv.y;
    float v = hsv.z;

    float a_ = cos(2.f * M_PI * h);
    float b_ = sin(2.f * M_PI * h);
    
    vec2 cusp = find_cusp(a_, b_);
    vec2 ST_max = to_ST(cusp);
    float S_max = ST_max.x;
    float T_max = ST_max.y;
    float S_0 = 0.5f;
    float k = 1.f- S_0 / S_max;

    // first we compute L and V as if the gamut is a perfect triangle:

    // L, C when v==1:
    float L_v = 1.f   - s * S_0 / (S_0 + T_max - T_max * k * s);
    float C_v = s * T_max * S_0 / (S_0 + T_max - T_max * k * s);

    float L = v * L_v;
    float C = v * C_v;

    // then we compensate for both toe and the curved top part of the triangle:
    float L_vt = toe_inv(L_v);
    float C_vt = C_v * L_vt / L_v;

    float L_new = toe_inv(L);
    C = C * L_new / L;
    L = L_new;

    vec3 rgb_scale = oklab_to_linear_srgb(vec3( L_vt, a_ * C_vt, b_ * C_vt ));
    float scale_L = cbrt(1.f / max(max(rgb_scale.r, rgb_scale.g), max(rgb_scale.b, 0.f)));

    L = L * scale_L;
    C = C * scale_L;

    vec3 rgb = oklab_to_linear_srgb(vec3( L, C * a_, C * b_ ));
    return vec3(
      srgb_transfer_function(rgb.r),
      srgb_transfer_function(rgb.g),
      srgb_transfer_function(rgb.b)
    );
  }

  vec3 srgb_to_okhsv(vec3 rgb) {
    vec3 lab = linear_srgb_to_oklab(vec3(
      srgb_transfer_function_inv(rgb.r),
      srgb_transfer_function_inv(rgb.g),
      srgb_transfer_function_inv(rgb.b)
      ));

    float C = sqrt(lab.y * lab.y + lab.z * lab.z);
    float a_ = lab.y / C;
    float b_ = lab.z / C;

    float L = lab.x;
    float h = 0.5f + 0.5f * atan(-lab.z, -lab.y) / M_PI;

    vec2 cusp = find_cusp(a_, b_);
    vec2 ST_max = to_ST(cusp);
    float S_max = ST_max.x;
    float T_max = ST_max.y;
    float S_0 = 0.5f;
    float k = 1.f - S_0 / S_max;

    // first we find L_v, C_v, L_vt and C_vt

    float t = T_max / (C + L * T_max);
    float L_v = t * L;
    float C_v = t * C;

    float L_vt = toe_inv(L_v);
    float C_vt = C_v * L_vt / L_v;

    // we can then use these to invert the step that compensates for the toe and the curved top part of the triangle:
    vec3 rgb_scale = oklab_to_linear_srgb(vec3( L_vt, a_ * C_vt, b_ * C_vt ));
    float scale_L = cbrt(1.f / max(max(rgb_scale.r, rgb_scale.g), max(rgb_scale.b, 0.f)));

    L = L / scale_L;
    C = C / scale_L;

    C = C * toe(L) / L;
    L = toe(L);

    // we can now compute v and s:

    float v = L / L_v;
    float s = (S_0 + T_max) * C_v / ((T_max * S_0) + T_max * k * C_v);

    return vec3 (h, s, v );
  }

  void main() {
    vec3 col = okhsv_to_srgb(vec3(uHue, fragTexCoord.x, 1 - fragTexCoord.y));
    finalColor = vec4(col, 1.0);
  }
  EOF

  def hue_shader
    HUE_SHADER
  end

  def picker_shader
    PICKER_SHADER
  end

  def render(canvas)
    self.top = canvas.y
    self.left = canvas.x
    self.height = canvas.height
    self.width = canvas.width

    yield canvas
  end
end
class Hokusai::Blocks::TranslationBlock < Hokusai::Block
  template <<~EOF
  [template]
    dynamic { @size_updated="set_size" }
      slot
  EOF

  uses(dynamic: Hokusai::Blocks::Dynamic)

  attr_accessor :content_width, :content_height

  def set_size(width, height)
    self.content_width = width
    self.content_height = height
    node.meta.set_prop(:width, width)
    node.meta.set_prop(:height, height)
  end

  computed :duration, default: 500.0, convert: proc(&:to_f)
  computed :from, default: :top, convert: proc(&:to_sym)

  def on_mounted
    @start = Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond)
  end

  def circular_in(t)
    return 1.0 - Math.sqrt(1.0 - t * t);
  end

  def bounce_out(x)
    n1 = 7.5625;
    d1 = 2.75;
    if (x < 1 / d1)
        return n1 * x * x;
    elsif (x < 2 / d1)
        return n1 * (x -= 1.5 / d1) * x + 0.75;
    elsif (x < 2.5 / d1)
        return n1 * (x -= 2.25 / d1) * x + 0.9375;
    else
        return n1 * (x -= 2.625 / d1) * x + 0.984375;
    end
  end

  def bounce_in(t)
    return 1.0 - bounce_out(1.0 - t);
  end

  def ease(x)
    return 1 - Math.cos((x * Math::PI) / 2);
  end

  def render(canvas)
    @canvas ||= canvas
    time = Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond) - @start

    if time > duration
      yield canvas

      return
    else
      case from
      when :top
        @startx ||= canvas.x
        @starty ||= canvas.y - canvas.height
      when :left
        @startx ||= canvas.x - canvas.width
        @starty ||= canvas.y
      when :right
        @startx ||= canvas.x + canvas.width
        @starty ||= canvas.y
      when :bottom
        @startx ||= canvas.x
        @starty ||= canvas.y + canvas.height
      end
      
      @targetx ||= canvas.x
      @targety ||= canvas.y
      
      progress = bounce_in(time.to_f / duration)

      if progress >= 1
        progress = 1.0
      end

      canvas.x = (@startx + (-@startx * progress)) + (@targetx * progress)
      canvas.y = (@starty + (-@starty * progress)) + (@targety * progress)

      yield canvas
    end
  end
end

module Hokusai::Blocks
  class Slider < Hokusai::Block
    style <<~EOF
    [style]
    cursorStyle {
      cursor: "pointer";
    }
    EOF
  
    template <<~EOF
    [template]
      empty {
        ...cursorStyle
        @click="start_slider"
        @mousemove="move_slider"
        @mouseup="stop_slider"
      }
    EOF

    uses(empty: Hokusai::Blocks::Empty)

    computed :fill, default: [61,171,211], convert: Hokusai::Color
    computed :background, default: [33,33,33], convert: Hokusai::Color
    computed :circle_color, default: [244,244,244], convert: Hokusai::Color
    computed :initial, default: 0, convert: proc(&:to_i)
    computed :size, default: 20.0, convert: proc(&:to_f)
    computed :step, default: 20, convert: proc(&:to_i)
    computed :min, default: 0, convert: proc(&:to_i)
    computed :max, default: 100, convert: proc(&:to_i)
    computed :padding, default: [10.0, 10.0, 0.0, 10.0], convert: Hokusai::Padding

    attr_reader :slider_width, :slider_start, :steps_x, :steps_val
    attr_accessor :sliding, :slider_x, :last_index

    def initialize(**args)
      @sliding = false
      @slider_width = 0.0
      @slider_start = 0.0
      @slider_x = 0.0
      @last_index = 0
      @configured = false

      super

      @last_max = nil
    end

    def prevent(event)
      event.stop
    end

    def start_slider(event)
      self.sliding = true
      event.stop
    end

    # step can be a float
    def steparr(min, max, step, edge = 0)
      nums = [min]
      while min < max
        if min + step > max
          nums[-1] = max - edge
        else
          nums << min + step
        end
  
        min = min + step 
      end
      nums
    end

    def on_resize(canvas)
      # create our buckets for steps
      @slider_start = canvas.x.to_i + padding.left.to_i
      @slider_width = canvas.width - padding.width

      sw = slider_width - (size / 2)

      valarr = steparr(min, max, step)
      sx = sw / (valarr.size.to_f - 1)
      xarr = steparr(slider_start.to_f, slider_start + sw, sx, size / 2.0)

      @steps_x = xarr
      @steps_val = valarr
    end

    def move_slider(event)
      if sliding && event.left.down
        pos = event.pos.x
        index = steps_x.size - 1
    
        (0...steps_x.size - 1).each do |i|
          if steps_x[i + 1] && pos - steps_x[i + 1] > step && i < steps_val.size - 1
            next
          end

          if pos - steps_x[i] > pos - steps_x[i + 1]
            index = i
            break 
          else
            if i < steps_val.size 
              index = i + 1
            end
            break
          end
        end

        if last_index != index
          emit("change", steps_val[index])
        end
        event.stop
        self.last_index = index unless index >= steps_val.size || steps_val[index].nil?
      elsif event.left.up
        self.sliding = false
      end
    end

    def stop_slider(event)
      if event.left.up
        self.sliding = false
      end

      # event.stop
    end

    #            ┌───────────────────── canvas.width ──────────────────────┐    
    #        │                                                         │    
    #        │   ┌────────────────────────────────────────────────┐    │    
    #            │slider_width = canvas.width - slider_start - padding.right
    #        ┌───┴────────────────────────────────────────────────┴────┐    
    #        │                                                         │    
    #        │   ┌────────────xxxx────────────────────────────────┐    │    
    #        │   │           xxxxxx                               │    │    
    #        │   │      │    xxxxxx                               │    │    
    #        │   └──────┼─────xxxx────────────────────────────────┘    │    
    #        │          │      │                                       │    
    #        ├───┬──────┼──────┼───────────────────────────────────────┘    
    #        │   │      │      │                                            
    #        │   │      │      │                                            
    #        ▼   │      │      └► cursor_x                                  
    # canvas.x   │      │                                                   
    #            │      │                                                   
    #            │      │   slider_start = canvas.x + padding.left          
    #        ┌───┤      │                                                   
    #        │   │      │                                                   
    #        ▼   ▼      │                                                   
    #    padding.left   │                                                   
    #                   └────────► fill_x = slider_start
    #                              fill_w = slider_x - slider_start + padding.width 
    def render(canvas)
      if max != @last_max
        on_resize(canvas)

        @last_max = max
      end

      unless @setup || steps_val.nil? || initial.nil?
        steps_val.each_with_index do |val, index|
          if val == initial
            self.last_index = index

            break
          end
        end

        @setup = true
      end

      slider_x = steps_x[last_index]
      cursor = slider_x + (size / 2)
      cslider_width = slider_x - slider_start + padding.width

      draw do
        # slider background
        rect(slider_start, canvas.y + padding.top, slider_width, size) do |command|
          command.round = size / 2
          command.color = background
        end

        # slider fill
        rect(slider_start, canvas.y + padding.top, cslider_width, size) do |command|
          command.round = size / 2
          command.color = fill
        end

        if sliding
          circle(cursor, canvas.y + padding.top + (size / 2), size) do |command|
            command.color = Hokusai::Color.new(circle_color.r, circle_color.g, circle_color.b, 50)
          end
        end

        circle(cursor, canvas.y + padding.top + (size / 2), size / 2) do |command|
          command.color = circle_color
        end
      end

      yield canvas
    end
  end
end


module Hokusai::Util
  class Wrapped
    attr_accessor :y
    attr_accessor :text, :x, :width, :height, :extra, :widths, :positions
    
    def initialize(text, rect, extra, widths:, positions:)
      @text = text
      @x = rect.x
      @y = rect.y
      @width = rect.width
      @height = rect.height
      @widths = widths
      @extra = extra
      @positions = positions
    end

    def range
      positions.first..positions.last
    end
  end

  class WrapCachePayload
    attr_accessor :copy, :positions, :cursor
    
    def initialize(copy, positions, cursor)
      @copy = copy
      @positions = positions
      @cursor = cursor
    end
  end

  # A cache that stores the results of WrapStream.
  # Utiltiy methods are provided to quickly fetch a subset of tokens
  # Based on a given window's coordinates (canvas)
  class WrapCache
    attr_accessor :tokens

    # returns range denoting the index of the changed lines
    # from 2 different strings.
    # NOTE: the change must be consecutive
    def self.diff(first, second)
      arr = (0..first.length).to_a

      v = arr.bsearch do |i|
        first.rindex(second[0..i]) != 0
      end

      # bounds checks
      v = first.size if v.nil?
      v -= 1 if first[v] == "\n"

      a = 0
      while true
        if first[v] == "\n"
          a = v + 1
          break
        elsif v.zero?
          a = v
          break
        end
        v -= 1
      end

      b = a
      while true
        if first[b].nil?
          b = first.size - 1
          break
        elsif first[b] == "\n"
          break
        end
        b += 1
      end

      a..b
    end

    def initialize
      @tokens = []
    end

    def <<(element)
      @tokens << element
    end

    def splice(stream, last_content, new_content, selection: nil)
      change_line_indicies = WrapCache.diff(last_content, new_content)
      new_changed_line_indicies = WrapCache.diff(new_content, last_content)

      new_data = new_content[new_changed_line_indicies]
      old_text_callback = stream.on_text_cb
      records = []
      # the height of the new records
      records_height = 0.0

      stream.on_text do |wrapped|
        unless wrapped.positions.empty?
          records_height += wrapped.height
          wrapped.positions.map! do |pos|
            pos + change_line_indicies.begin
          end
          records << wrapped
        end
      end

      stream.wrap(new_data, nil)
      stream.flush

      # puts ["original.tokens.last.y", tokens.last.y].inspect

      # splice in new tokens
      #
      # update the new positions
      # NOTE: still need to udpate the y positions with the 
      # records.each do |record|
      #   records_height += record.height
      #   record.positions.map! do |pos|
      #     pos + change_line_indicies.begin
      #   end
      # end

      diff_pos = (new_changed_line_indicies.end - change_line_indicies.end)
      new_tokens = []
      found = false
      last_token = nil
      new_last_tokens_height = 0.0
      last_tokens_height = 0.0
      insert_index = 0

      while token = tokens.shift
        next if token.positions.empty?
        if token.range.begin >= change_line_indicies.begin && token.range.end <= change_line_indicies.end
          # this is a match
          # we want to remove these tokens from the list...and then sub in our new tokens.
          last_token = token
          last_tokens_height += token.height
          found = true
          next
        end

        if found
          token.y += (records_height - last_tokens_height)

          token.positions.map! do |pos|
            pos + diff_pos
          end
        else
          insert_index += 1
          new_last_tokens_height += token.height
        end

        new_tokens << token
      end

      records.each do |record|
        record.y += new_last_tokens_height
      end

      # puts ["insert", records.first.y, records.map(&:height).sum, insert_index, new_last_tokens_height].inspect

      new_tokens.insert(insert_index, *records)
      self.tokens = new_tokens
      

      # i = 0
      # tokens.each do |token|
      #   # puts ["token", token].inspect
      #   token.positions.each do |n|
      #     if n != i
      #       puts ["Mismatch token", token, i, n].inspect
      #     end

      #     i += 1
      #   end
      # end

      # restore callback
      stream.on_text(&old_text_callback)
      # return y
      tokens.last.y + tokens.last.height
    end

    def bsearch(canvas)
      low = 0
      high = tokens.size - 1

      while low <= high
        mid = low + (high - low) / 2

        if matches(tokens[mid], canvas)
          return mid
        end

        if tokens[mid].y > canvas.y
          high = mid - 1
        end

        if tokens[mid].y < canvas.y
          low = mid + 1
        end
      end

      return nil
    end

    def matches(wrapped, canvas)
      wrapped.y >= canvas.y && wrapped.y <= canvas.y + canvas.height
    end

    #  arrows = cursor index
    #  letters = selected positions
    #                          
    #  │     │      │     │     │  
    #  │  A  │   B  │  C  │  D  │  
    #  │     │      │     │     │  
    #  ▼  0  ▼   1  ▼  2  ▼  3  ▼  
    #                           
    #  -1    0      1     2     3  
    #                            
    def selected_area_for_tokens(tokens, selector, copy: false, padding: Hokusai::Padding.default)
      return if selector.nil? || !selector.selecting?

      copy_buffer = ""
      x = nil
      tw = 0.0
      cy = nil
      position_buffer = []
      cursor = nil
      pcursor = nil

      tokens.each do |token|
        tx = token.x + padding.left
        ty = token.y + padding.top

        if token.y != cy
          x = nil
          cy = token.y
          tw = 0.0
        end

        token.widths.each_with_index do |w, i|
          by = selector.geom.frozen? ? ty : ty - selector.offset_y
          sy = ty

          if (selector.geom? && selector.geom.selected(tx, by, w, token.height))
            if (selector.geom.left? || selector.geom.up?)
              cursor ||= [tx, sy, 0.5, token.height]
              pcursor ||= token.positions[i]
            else
              # puts ["set selection cursor: #{sy}"]
              cursor = [tx + w, sy, 0.5, token.height]
              pcursor = token.positions[i]
            end

            position_buffer << token.positions[i]

            if copy
              copy_buffer += token.text[i]
            end

            if x.nil?
              x = tx
            end

            tw += w
          elsif selector.pos? && selector.pos.selected(token.positions[i])
            # puts ["pos 1"]
            if selector.pos.cursor_index == selector.pos.positions.first
              cursor ||= [tx, sy, 0.5, token.height]
              pcursor ||= token.positions[i]
            elsif selector.pos.cursor_index == selector.pos.positions.last
              cursor = [tx + w, sy, 0.5, token.height]
              pcursor = token.positions[i]
            elsif selector.pos.cursor_index + 1 == token.positions[i]
              cursor = [tx, sy, 0.5, token.height]
              pcursor = token.positions[i] - 1
            end

            position_buffer << token.positions[i]

            if copy
              copy_buffer += token.text[i]
            end

            if x.nil?
              x = tx
            end

            tw += w

          # [0, [0]]
          elsif selector.pos? && selector.pos.cursor_index && selector.pos.cursor_index + 1 == token.positions[i]
            # puts "pos 2"
            cursor = [tx, sy, 0.5, token.height]
            pcursor = token.positions[i] - 1
            # position_buffer = selector.pos.positions

            # if copy
            #   copy_buffer += token.text[i]
            # end

          elsif selector.pos? && selector.pos.cursor_index && selector.pos.cursor_index == token.positions[i]
            # puts "pos 3"
            cursor = [tx + w, sy, 0.5, token.height]
            pcursor = selector.pos.cursor_index
            # position_buffer = selector.pos.positions
          elsif selector.geom? && selector.geom.clicked(tx, by, (w / 2), token.height)
            cursor = [tx, sy, 0.5, token.height]
            pcursor = token.positions[i] - 1
            # puts "setting cursor #{sy}"

          elsif selector.geom? && selector.geom.clicked(tx + (w/2.0), by, (w/2.0), token.height)
            # puts "geom click 2"
            cursor = [tx + w, sy, 0.5, token.height]
            pcursor = token.positions[i]
          end
          
          tx += w
        end

        if !x.nil?
          ay = cy + padding.top - selector.offset_y
          yield Hokusai::Rect.new(x, ay, tw, token.height)

          tw = 0.0
        end
      end

      selector.pos.cursor_index = pcursor
      selector.pos.positions = position_buffer
      selector.geom.cursor = cursor

      WrapCachePayload.new(copy_buffer, position_buffer, pcursor)
    end

    def tokens_for(canvas)
      index = bsearch(canvas)
      return [] if index.nil?
      lindex = index.zero? ? index : index - 1
      rindex = index + 1

      while rindex < tokens.size - 1 && matches(tokens[rindex], canvas)
        rindex += 1
      end

      while lindex > 0 && matches(tokens[lindex], canvas)
        lindex -= 1
      end

      tokens[lindex..rindex].clone
    end
  end

  # A disposable streaming text wrapper
  # tokens can be appended onto it, where it they will break on a given width.
  # Opaque payloads can be passed for each token, which will be provided to callbacks.
  # This makes it suitable for processing and wrapping markdown/html/tokenized text
  #
  # height of the wrapped text is tracked with `stream#y`
  class WrapStream
    attr_accessor :buffer, :x, :y, :origin_y, :current_width, :stack, :widths, :current_position, :positions, :on_text_cb
    attr_reader :width, :origin_x, :on_text_cb

    def initialize(width, origin_x = 0.0, origin_y = 0.0, &measure)
      @width = width            # the width of the container for this wrap
      @measure_cb = measure     # a measure callback that returns the width/height of a given char (takes 2 params: a char and an token payload)
      @on_text_cb = ->(_) {}    # a callback that receives a wrapped token for a given line.  (takes a Hokusai::Util::Wrapped paramter)

      @origin_x = origin_x      # the origin x coordinate, x will reset to this
      @x = origin_x             # the marker for x coord, this is used to track against the width of a given line
      @y = origin_y             # the marker for the y coord, this grows by <size> for each line, resulting in the height of the wrapped text
      @current_width = 0.0      # the current width of the buffer
      @stack = []               # a stack storing buffer offsets with their respective token payloads.
      @buffer = ""              # the current buffer that the stack represents.
      
      @current_position = 0     # the current char index
      @positions = []           # a stack of char positions, used for editing
      @widths = []              # a stack of char widths, used later in selection
    end

    NEW_LINE_REGEX = /\n/

    # Appends <text> to the wrap stream.
    # If the text supplies causes the buffer to grow beyond the supplied width
    # The buffer will be flushed to the <on_text_cb> callback.
    #
    # @param [String] text (text to append to this wrap stream)
    # @param [Object] extra (an opaque payload that will be passed to callbacks)
    def wrap(text, extra)
      offset = 0
      size = text.size
      
      # appends the initial stack value for this text
      stack << [((buffer.size)..(text.size + buffer.size - 1)), extra]

      # char-by-char processing.
      while offset < size
        char = text[offset]
        self.current_position = offset

        w, h = measure(char, extra)

        # this char is actually a newline.
        if NEW_LINE_REGEX.match(char)
          self.widths << 0
          self.buffer << char
          self.positions << current_position
          flush

          # append the rest of this text to the stack.
          stack << [(0...(text.size - offset - 1)), extra]
          self.y += h
          self.x = origin_x
          offset += 1

          next
        end

        # adding this char will extend beyond the provided width
        if w + current_width >= width
          # if this is a space in the second half of this line, 
          # split the buffer @ it's index and render
          idx = buffer.rindex(" ")
          if !idx.nil?
            cur = []
            nex = []

            found = false

            # we need to split up the buffer and the ranges.
            while payload = stack.shift
              range, xtra = payload

              # this range contains the space
              # we will split the stack here
              if range.include?(idx)
                cur << [(range.begin..idx), xtra]
                nex << [(0..(range.end - idx - 1)), xtra] unless idx == range.end
              
                found = true
              # the space has not been found
              # append to first stack
              elsif !found
                cur << payload
              # the space has been found
              # append to second stack.
              # (note: we need to subtract the idx from the range because 
              #        we are flushing everything before the space)
              else
                nex << [((range.begin - idx - 1)..(range.end - idx - 1)), xtra] 
              end
            end

            # get the string values from the buffer
            scur = buffer[0..idx]
            snex = buffer[(idx + 1)..-1]

            wcur = widths[0..idx]
            wnex = widths[(idx + 1)..-1]

            pcur = positions[0..idx]
            pnex = positions[(idx + 1)..-1]

            # set the buffer and stack to everything before the space
            self.buffer = scur
            self.widths = wcur
            self.stack = cur
            self.positions = pcur

            flush

            # set the buffer and stack to everything after the space
            self.buffer = snex + char
            self.widths = wnex.concat([w])
            self.positions = pnex.concat([current_position])
            self.stack = nex
            self.x = origin_x
            self.current_width = widths.sum#measure(buffer, xtra).first


            # bump the height
            self.y += h
          # no space: force a break on the char.
          else
            flush

            self.current_width = w
            self.y += h
            self.buffer = text[offset]
            self.widths = [w]
            self.positions = [current_position]
            stack << [(0...(text.size - offset)), xtra]
          end
        # append this char does NOT extend beyond the width
        else
          self.current_width += w
          buffer << char
          widths << w
          positions << current_position
        end

        offset += 1
      end
    end

    # Flushes the current buffer/stack.
    def flush
      stack.each do |(range, extra)|
        content = buffer[range]
        size = content.size
        content_width, content_height = measure(content, extra)

        wrap_and_call(content, content_width, content_height, extra)
        self.x += content_width
      end

      self.buffer = ""
      self.current_width = 0.0
      stack.clear
      widths.clear
      positions.clear
      self.x = origin_x
    end

    def on_text(&block)
      @on_text_cb = block
    end

    private

    def wrap_and_call(text, width, height, extra)
      rect = Hokusai::Rect.new(x, y, width, height)
      @on_text_cb.call Wrapped.new(text.dup, rect, extra, widths: widths.dup, positions: positions.dup)
    end

    def measure(string, extra)
      @measure_cb.call(string, extra)
    end
  end
end

module Hokusai::Util
  class GeometrySelection
    attr_accessor :start_x, :start_y, :stop_x, :stop_y,
                  :type, :cursor, :diff, :click_pos, :parent

    def initialize(parent)
      @parent = parent
      @type = :none         # state for the geometry selection (active/frozen/etc)
      @start_x = 0.0        # the x coordinate for the geometry
      @stary_y = 0.0        # the y coordinate for the geometry 
      @stop_x = 0.0
      @stop_y = 0.0
      @diff = 0.0
      @cursor = nil
      @click_pos = nil
    end

    def set_click_pos(x, y)
      @click_pos = [x, y]
    end

    def none?
      type == :none
    end

    def ready?
      type == :none || type == :frozen
    end

    def clear
      self.start_x = 0.0
      self.start_y = 0.0
      self.stop_x = 0.0
      self.stop_y = 0.0
      self.cursor = nil
    end

    def changed_direction?
      @changed_direction
    end

    def active?
      type == :active
    end

    def frozen?
      type == :frozen
    end

    def activate!
      self.type = :active
    end

    def freeze!
      self.type = :frozen
    end

    def coords
      [start_x, stop_x, start_y, stop_y]
    end

    def start(x, y)
      self.start_x = x
      self.start_y = y
      self.stop_x = x
      self.stop_y = y
      self.cursor = nil

      activate!
    end

    def stop(x, y)
      self.stop_x = x
      self.stop_y = y

      if up? && @direction == :down || down? && @direction == :up
        @changed_direction = true
      else
        @changed_direction = false
      end

      @direction = up? ? :up : :down
    end

    def up?(height = 0)
      stop_y < start_y - height
    end

    def down?(height = 0)
      start_y <= stop_y - height
    end

    def left?
      stop_x < start_x
    end

    def right?
      start_x <= stop_x
    end

    def cursor
      return nil unless @cursor

      return [@cursor[0], @cursor[1] - parent.offset_y, @cursor[2], @cursor[3]] if frozen?

      @cursor
    end

    def rect_selected(rect)
      selected(rect[0], rect[1], rect[2], rect[3])
    end

    def clicked(x,y,w,h)
      return false if click_pos.nil?

      pos = Hokusai::Rect.new(x, y, w, h)
      # pos.move_x_left
      pos.includes_x?(click_pos[0]) && pos.includes_y?(click_pos[1])
    end

    def selected(x, y, width, height)
      return false if none?

      if frozen?
        y -= parent.offset_y
      end

      sx = @start_x
      sy = @start_y
      ex = @stop_x
      ey = @stop_y

      down = sy <= ey
      up = ey < sy
      left = ex < sx
      right = sx <= ex

      rect = Hokusai::Rect.new(x, y, width, height)
      x_shifted_right = rect.move_x_right(1)
      y_shifted_up = rect.move_y_up(2)
      y_shifted_down = rect.move_y_down(2)
      end_y = y + height

      a = ((down &&
        # first line of multiline selection
        ((x_shifted_right > sx && end_y < ey && rect.includes_y?(sy)) ||
          # last line of multiline selection
          (x_shifted_right <= ex && y_shifted_up + height < ey && y > sy) ||
          # middle line (all selected)
          (y > sy && end_y < ey))) ||
        (up &&
          # first line of multiline selection
          ((x_shifted_right <= sx && y > ey && rect.includes_y?(sy)) ||
          # last line of multiline selection
            (x_shifted_right >= ex && y_shifted_down > ey && end_y < sy) ||
            # middle line (all selected)
            (y > ey && y + height < sy))) ||
        # single line selection
        ((rect.includes_y?(sy) && rect.includes_y?(ey)) &&
          ((left && x_shifted_right < sx && x_shifted_right > ex) || (right && x_shifted_right > sx && x_shifted_right < ex)))
      )

      a
    end
  end
end
module Hokusai::Util
  class PositionSelection
    attr_accessor :positions, :cursor_index, :direction, :active

    def initialize
      @cursor_index = nil
      @positions = []
      @direction = :right
      @active = false
    end

    def move(to, selecting)
      self.active = selecting
  
      return if cursor_index.nil?

      # puts ["before", to, cursor_index, positions].inspect
      
      case to
      when :right
        self.cursor_index += 1
        if selecting && !positions.empty? && cursor_index <= positions.last
          positions.shift
        elsif selecting
          positions << cursor_index 
        end

      when :left
        if selecting && !positions.empty? && cursor_index >= positions.last
          positions.pop
        elsif selecting
          positions.unshift cursor_index
        end
  
        self.cursor_index -= 1 unless cursor_index == -1
      end
    end

    def active?
      @active
    end

    def left?
      direction == :left
    end

    def right?
      direction == :right
    end

    def clear
      self.cursor_index = nil
      positions.clear
    end

    def selected(index)
      active && (positions.first..positions.last).include?(index)
    end

    def select(range)
      self.positions = range.to_a
    end
  end
end

module Hokusai::Util
  class SelectionNew
    attr_reader :geom, :pos
    attr_accessor :type, :offset_y, :diff, :cursor

    def initialize
      @geom = GeometrySelection.new(self)
      @pos = PositionSelection.new
      @type = :geom
      @offset_y = 0.0
      @diff = 0.0
      @cursor = nil
    end

    def clear
      pos.clear
      geom.clear
    end

    def cursor
      geom.cursor
    end

    def geom!
      pos.clear
      pos.cursor_index = nil

      self.type = :geom
    end

    def pos!
      geom.clear

      self.type = :pos
    end

    def geom?
      type == :geom
    end

    def pos?
      type == :pos
    end

    def left?
      geom? ? geom.left? : pos.left?
    end

    def right?
      geom? ? geom.right? : pos.right?
    end

    def up?
      geom? && geom.up?
    end

    def down?
      geom? && geom.down?
    end

    def selecting?
      !(geom.type == :none && geom.click_pos.nil?)
    end

    # should we show the cursor?
    def active?
      !cursor.nil?
    end
  end
end

class Hokusai::Blocks::Text < Hokusai::Block
  template <<~EOF
  [template]
    empty {
      @keypress="check_copy"
    }
  EOF

  uses(empty: Hokusai::Blocks::Empty)

  computed! :content
  computed :background, default: [255, 255, 255], convert: Hokusai::Color
  computed :color, default: [222,222,222], convert: Hokusai::Color
  computed :selection_color, default: [43, 63, 61], convert: Hokusai::Color
  computed :selection_color_to, default: [0, 33, 233], convert: Hokusai::Color
  computed :animate_selection, default: false
  computed :padding, default: [20.0, 20.0, 20.0, 20.0], convert: Hokusai::Padding
  computed :font, default: nil
  computed :size, default: 15, convert: proc(&:to_i)
  computed :copy_text, default: false

  inject :panel_top
  inject :panel_height
  inject :panel_content_height
  inject :panel_offset
  inject :selection

  attr_accessor :copying, :copy_buffer, :measure_map, :last_content, :breaked, :render_height, :last_size, :last_y,
                :heights_loaded

  def on_mounted
    @copying = false
    @last_content = nil
    @last_size = nil
    @last_y = nil
    @heights_loaded = false
    @copy_buffer = ""
    @measure_map = nil
    @render_height = 0.0
    @breaked = false

    @progress = 0
    @back = false
  end

  def check_copy(event)
    if (event.ctrl || event.super) && event.symbol == :c
      self.copying = true
    end
  end

  def user_font
     font ? Hokusai.fonts.get(font) : Hokusai.fonts.active
  end

  def wrap_cache(canvas, force = false)

    should_splice = last_content != content && !last_content.nil?

    return @wrap_cache unless force || should_splice || !heights_loaded || breaked || @wrap_cache.nil?

    # if there's no cache, new / wrap
    # if the heights aren't loaded - new / wrap
    # if the content changed - use / splice
    # if forced / resized - new / wrap
    if force || !heights_loaded || breaked || @wrap_cache.nil?
      @wrap_cache = Hokusai::Util::WrapCache.new
    end

    self.breaked = false

    # for one big text, we want to use panel_top because canvas.y get's fucked on scroll
    # for looped items, we wawnt to use canvas.y    
    # puts ["canvas.y stream", canvas.y, panel_offset].inspect
    stream = Hokusai::Util::WrapStream.new(width(canvas), canvas.x, canvas.y + (panel_offset || 0)) do |string, extra|
      if w = user_font.measure_char(string, size)
        [w, size]
      else
        [user_font.measure(string, size).first, size]
      end
    end

    if should_splice
      stream.y = @wrap_cache.splice(stream, last_content, content)
    else
      stream.on_text do |wrapped|
        @wrap_cache << wrapped
      end

      stream.wrap(content, nil)
    end

    stream.flush
    self.render_height = stream.y

    if !last_y.nil?
      self.heights_loaded = true
    end

    self.last_y = canvas.y
    self.last_content = content.dup
    self.last_size = size

    @wrap_cache
  end

  def on_resize(canvas)
    self.breaked = true
  end

  def width(canvas)
    canvas.width - padding.width
  end

  def should_refresh(canvas)
    if breaked || last_size != size || (!heights_loaded)
      return true
    end

    false
  end

  # A fragment shader to rotate tint on asteroids
  def fshader
    <<-EOF
    #version 330
    in vec4 fragColor;
    in vec2 fragTexCoord;
    out vec4 finalColor;
    uniform sampler2D texture0;
    uniform vec4 from;
    uniform vec4 to;
    uniform float progress;

    void main() {
      vec4 texelColor = texture(texture0, fragTexCoord) * fragColor;

      finalColor.a = texelColor.a;
      finalColor.rgb = mix(from, to, progress).rgb;
    }
    EOF
  end

  def render(canvas)
    poffset = panel_offset || canvas.y
    pheight = panel_height || canvas.height
    pcheight = panel_content_height ||= canvas.height
    pptop = panel_top.nil? ? canvas.y : panel_top - canvas.y
    ptop = canvas.y + poffset

    cache = wrap_cache(canvas, should_refresh(canvas))
    diff = 0.0

    if selection
      selection.offset_y = poffset if selection.geom.active?
      diff = selection.offset_y - poffset
      selection.diff = diff
    end

    draw do
      tokens = cache.tokens_for(Hokusai::Canvas.new(canvas.width, pheight, canvas.x + padding.left, poffset))
      pad = Hokusai::Padding.new(padding.top, 0.0, 0.0, padding.left)

      if selection && animate_selection
        shader_begin do |command|
          command.fragment_shader = fshader
          command.uniforms = {
            "from" => [selection_color.to_shader_value, HP_SHADER_UNIFORM_VEC4], 
            "to" => [selection_color_to.to_shader_value, HP_SHADER_UNIFORM_VEC4],
            "progress" => [@progress, HP_SHADER_UNIFORM_FLOAT]
          }
        end
      end

      copied = cache.selected_area_for_tokens(tokens, selection, copy: copying || copy_text, padding: pad) do |rect|
        rect(rect.x, rect.y + diff, rect.width, rect.height) do |command|
          command.color = selection_color
        end
      end

      emit("selected", copied) unless copied.nil?

      if copying
        Hokusai.copy(copied.copy)
        self.copying = false
      end

      if copy_text
        emit("copy", copied)
      end

      if selection && animate_selection
        shader_end
      end

      tokens.each do |wrapped|
        # handle selection
        rect = Hokusai::Rect.new(wrapped.x + pad.left, (wrapped.y - (panel_offset || 0.0)) + padding.top, wrapped.width, wrapped.height)
        # draw text
        text(wrapped.text, rect.x, rect.y) do |command|
          command.color = color
          command.size = size
          if font
            command.font = Hokusai.fonts.get(font)
          end
        end
      end
    end

    node.meta.set_prop(:height, render_height)
    emit("height_updated", render_height)

    if @back
      @progress -= 0.02
    else
      @progress += 0.02
    end

    if @progress >= 1 && !@back
      @back = true
    elsif @progress <= 0 && @back
      @progress = 0
      @back = false
    end

    yield canvas
  end
end

class Hokusai::Blocks::Center < Hokusai::Block
  template <<~EOF
  [template]
    dynamic { @size_updated="update_size" }
      slot
  EOF

  attr_accessor :cwidth, :cheight

  uses(dynamic: Hokusai::Blocks::Dynamic)

  computed :horizontal, default: false
  computed :vertical, default: false

  def update_size(width, height)
    self.cwidth = width
    self.cheight = height
  end

  def render(canvas)
    a = cwidth ? cwidth / 2 : 0.0
    b = cheight ? cheight / 2 : 0.0

    canvas.x = (canvas.x + canvas.width) / 2.0 - a if horizontal || (!horizontal && !vertical)
    canvas.y = canvas.y + (canvas.height / 2.0) - b if vertical || (!horizontal && !vertical)

    yield canvas
  end
end
class Hokusai::Blocks::Tooltip < Hokusai::Block
  template <<~EOF
  [template]
    vblock
      vblock { @hover="set_active" @mouseout="unset_active"  @size_updated="update_size" }
        slot
      [if="active"]
        vblock { z="2" :zposition="zposition" :width="width" :height="height" :background="background" }
          text { :content="label" :size="size" :color="color" :padding="padding" }
  EOF

  computed! :label
  computed :direction, default: :down, convert: proc(&:to_sym)
  computed :size, default: 18, convert: proc(&:to_i);
  computed :padding, default: Hokusai::Padding.new(2.5, 15.0, 2.5, 15.0), convert: Hokusai::Padding
  computed :color, default: Hokusai::Color.new(22, 22, 22), convert: Hokusai::Color
  computed :background, default: Hokusai::Color.new(222,88,88), convert: Hokusai::Color

  uses(
    center: Hokusai::Blocks::Center,
    vblock: Hokusai::Blocks::Vblock,
    text: Hokusai::Blocks::Text,
    dynamic: Hokusai::Blocks::Dynamic
  )

  attr_accessor :active, :width, :height, :zposition

  def initialize(**args)
    @active = false
    @zposition = Hokusai::Boundary.default

    super
  end

  def after_updated
    if @width.nil?
      width, height = Hokusai.fonts.active.measure(label, size)
      @width = width + padding.width + 10.0
      @height = height + padding.height
    end
  end

  def set_active(_)
    self.active = true
  end

  def unset_active(_)
    self.active = false
  end

  def render(canvas)
    case direction
    when :down
      self.zposition = Hokusai::Boundary.new(10.0, 0.0, 0.0, (canvas.width  / 2.0) - ((width || 0.0) / 2.0))
    when :right
      self.zposition = Hokusai::Boundary.new(-((canvas.height / 2.0) + ((height || 0.0) / 2.0)), 0.0, 0.0, (canvas.width + 10.0))
    when :left
      self.zposition = Hokusai::Boundary.new(-(canvas.height / 2.0) + ((height || 0.0) / 2.0), 0.0, 0.0, -(canvas.width + 10.0))
    when :up
      self.zposition = Hokusai::Boundary.new(10.0, 0.0, 0.0, (canvas.width  / 2.0) - ((width || 0.0) / 2.0))
    end

    yield canvas
  end
end
class Hokusai::Blocks::Icon < Hokusai::Block
  template <<~EOF
  [template]
    virtual
  EOF

  MAP = {
    foo: "\u{E057}",
    forward: "\u{E00B}",
    heart: "\u{E085}",
    camera: "\u{E03B}",
    download: "\u{E065}",
    sun: "\u{E000}",
    messages: "\u{E0B9}",
    clipboard: "\u{E04A}",
    plus: "\u{E0CE}",
    minus: "\u{E0BC}",
    down: "\u{E01D}",
    up: "\u{E01E}"
  }

  computed! :type
  computed :size, default: 15, convert: proc(&:to_i)
  computed :color, default: Hokusai::Color.new(0, 0, 0), convert: Hokusai::Color
  computed :background, default: Hokusai::Color.new(255, 255, 255, 0), convert: Hokusai::Color
  computed :outline, default: Hokusai::Outline.default, convert: Hokusai::Outline
  computed :outline_color, default: Hokusai::Color.new(0, 0, 0, 0), convert: Hokusai::Color
  computed :padding, default: Hokusai::Padding.new(2.5, 5.0, 2.5, 5.0), convert: Hokusai::Padding
  computed :center, default: true

  def get_icon_from_type
    MAP[type.to_sym]
  end

  def center_in(canvas, size)
    x = canvas.x + (canvas.width / 2.0) - ((size / 2) || 0.0)
    y = canvas.y + (canvas.height / 2.0) - ((size / 2) || 0.0)

    [x, y]
  end

  def render(canvas)
    if Hokusai.fonts.get("icons")
      draw do
        rect(canvas.x, canvas.y, canvas.width, canvas.height) do |command|
          command.color = background
          command.outline = outline
          command.outline_color = outline_color
        end

        x, y = center_in(canvas, size)

        text(get_icon_from_type, x, y) do |command|
          command.font = Hokusai.fonts.get("icons")
          command.size = size
          command.color = color
        end
      end

      yield canvas
    end
  end
end
class Hokusai::Blocks::DropdownItem < Hokusai::Block
  style <<~EOF
  [style]
    container {
      cursor: "pointer";
    }
  EOF
  
  template <<~EOF
  [template]
    empty.container { ...container @mousedown="set_emit" @mouseup="emit_item"}
  EOF

  computed! :option
  computed :size, default: 24, convert: proc(&:to_i)
  computed :background, default: [22,22,22], convert: Hokusai::Color
  computed :outline, default: [1.0, 1.0, 1.0, 1.0], convert: Hokusai::Outline
  computed :outline_color, default: [55,55,55], convert: Hokusai::Color
  computed :color, default: [222,222,222], convert: Hokusai::Color
  computed :padding, default: [2.5, 5.0, 2.5, 5.0], convert: Hokusai::Padding
  computed :font, default: nil

  uses(
    empty: Hokusai::Blocks::Empty,
  )

  inject :panel_offset
  inject :panel_height
  inject :panel_top

  def set_emit(event)
    @emit_next = true
  end

  def content
    option.respond_to?(:value) ? option.value : option
  end

  def emit_item(event)
    if @emit_next
      emit("picked", option)
    end

    @emit_next = false
  end

  def update_height(height)
    node.meta.set_prop(:height, height)
    node.portal.meta.set_prop(:height, height)
  end

  def can_render(canvas)
    return true unless panel_offset && panel_height

    canvas.y + canvas.height > panel_top && canvas.y < panel_top + panel_height
  end

  def render(canvas)
    if can_render(canvas)
      draw do
        rect(canvas.x, canvas.y, canvas.width, canvas.height) do |command|
          command.color = background
          command.outline = outline
          command.outline_color = outline_color
          command.padding = padding
        end

        cy = canvas.y + (canvas.height / 2.0) - (size / 2)
        text(content, canvas.x + padding.left, cy) do |command|
          if font
            command.font = Hokusai.fonts.get(font)
          end
          command.size = size
          command.color = color
          command.padding = padding
        end
        
        yield canvas
      end
    end
  end
end
class Hokusai::Blocks::Dropdown < Hokusai::Block
  style <<~EOF
  [style]
  dropText {
    color: rgb(222,222,222);
    content: "Choose your destiny";
    outline: outline(0.0, 0.0, 1.0, 0.0);
    padding: padding(0.0, 0.0, 0.0, 20.0);
    outline_color: rgb(43, 43, 43);
  }

  dropIcon {
    width: 60.0;
    background: rgb(22,22,22);
    color: rgb(222,222,222);
    outline: outline(0.0, 1.0, 0.0, 1.0);
    outline_color: rgb(43, 43, 43);
    type: "down";
  }

  dropIcon@mousedown {
    color: rgb(22,22,22);
    background: rgb(222,88,88);
    cursor: "pointer";
  }

  itemStyle {
    z: 2;
    autoclip: true;
    background: rgb(22,22,22);
  }

  item {
    background: rgb(22,22,22);
    padding: padding(10.0, 5.0, 10.0, 20.0);
    outline: outline(0.0, 0.0, 1.0, 0.0);
    outline_color: rgb(44,44,44);
    color: rgb(222,222,222);
  }

  item@hover {
    background: rgb(222,88,88);
    color: rgb(22, 22, 22);
    cursor: "pointer";
  }
  
  dropContainer {
    background: rgb(22, 22, 22);
    outline: outline(1.0, 0.0, 1.0, 0.0);
    outline_color: rgb(43, 43, 43);
  }
  EOF

  template <<~EOF
  [template]
    vblock { @keypress="autocomplete" @click="prevent" @mousedown="prevent" @hover="prevent" @wheel="prevent" }
      hblock { ...dropContainer }
        text { ...dropText :padding="text_padding" :size="size" :content="active_content" }
        icon { ...dropIcon :size="size" @click="open"}
      [if="opened"]
        panel.panel {
          ...itemStyle 
          :zposition="zposition"
          :height="panel_height"
          @click="prevent"
          @wheel="prevent"
          @mousedown="prevent"
          @hover="prevent" 
          @mousemove="prevent" 
        }
          dynamic
            [for="item in filtered_options"]
              item { 
                ...item
                @picked="set_active" 
                :index="index"
                :height="height" 
                :key="option_key(item, index)" 
                :option="item" 
                :size="size"
              }
  EOF

  uses(
    center: Hokusai::Blocks::Center,
    vblock: Hokusai::Blocks::Vblock,
    hblock: Hokusai::Blocks::Hblock,
    text: Hokusai::Blocks::Text,
    icon: Hokusai::Blocks::Icon,
    item: Hokusai::Blocks::DropdownItem,
    panel: Hokusai::Blocks::Panel,
    dynamic: Hokusai::Blocks::Dynamic,
  )

  computed! :options
  computed :truncate, default: -1, convert: proc(&:to_i)
  computed :size, default: 24, convert: proc(&:to_i)
  computed :background, default: [22,22,22], convert: Hokusai::Color
  computed :color, default: [222,222,222], convert: Hokusai::Color
  computed :panel_height, default: 300.0, convert: proc(&:to_f)
  computed :direction, default: :down, convert: proc(&:to_sym)

  attr_accessor :buffer, :zposition

  def prevent(event)
    event.stop
  end

  def text_padding
    mheight = ((@height || 0.0) / 2.0)
    msize = (size / 2.0)
    top = mheight - msize
    Hokusai::Padding.new(top, 0.0, 0.0, 20.0)
  end

  def filtered_options
    if buffer.empty?
      options
    else
      options.select do |option|
        content(option).downcase.start_with?(buffer)
      end
    end
  end

  def autocomplete(key)
    if key.printable?
      @buffer << key.char
    elsif key.symbol == :backspace
      @buffer = @buffer[0..-2]
    end
  end
  
  def option_key(item, index)
    "#{content(item)}-#{index}"
  end

  def on_mounted
    @buffer = ""
  end

  attr_reader :opened, :height
  attr_accessor :active, :opened

  def open(event)
    self.opened = !opened
    @buffer = ""
  end

  def active_content
    self.active ||= options.first

    content(active)
  end

  def content(option)
    option.respond_to?(:value) ? option.value[0..truncate] : option[0..truncate]
  end

  def set_active(item)
    self.active = item
    self.opened = false
  end

  def render(canvas)
    @height ||= canvas.height

    case direction
    when :down
      self.zposition = Hokusai::Boundary.new(0.0, 0.0, 0.0, 0.0)
    when :up
      self.zposition = Hokusai::Boundary.new(-(@height + panel_height), 0.0, 0.0, 0.0)
    else
    end

    yield canvas
  end
end
