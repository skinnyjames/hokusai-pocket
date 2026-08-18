
module Hokusai
  # Public: Error class
  class Error < StandardError; end
end
module Hokusai
  # Public: A class to represent x,y coordinates
  class Vec2
    attr_accessor :x, :y
    def initialize(x, y)
      @x = x
      @y = y
    end
  end
  
  # Public: A class to represent a rectangle
  class Rect
    attr_accessor :x, :y, :width, :height

    def initialize(x, y, width, height)
      @x = x
      @y = y
      @width = width
      @height = height
    end

    # Public: combines rectangle with another rectangle
    # 
    # other - another Hokusai::Rect to add.
    # 
    # Returns a new Hokusai::Rect
    def add(other)
      ex = x + width
      ey = y + height

      oex = other.x + other.width
      oey = other.y + other.height

      mx = [x, other.x].min
      my = [y, other.y].min

      Hokusai::Rect.new(
        mx, my,
        [ex, oex].max - mx,
        [ey, oey].max - my
      )
    end

    # Public: Does this rectangle intersect with (other)?
    # 
    # other - a Hokusai::Rect to compare
    # 
    # Returns boolean
    def intersect?(other)
      (x - other.x).abs <= ((width)) && (y - other.y).abs <= ((height))
    end

    # Public: does this rectangle include (y)?
    # 
    # y - a y coordinate
    # 
    # Returns boolean
    def includes_y?(y)
      y > @y && y <= (@y + @height)
    end

    # Public: does this rectangle include (x)?
    # 
    # x - x coordinate
    # 
    # Returns boolean
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

    # Public: Constructor for Hokusai::Outline
    #
    # top - top outline width (Float)
    # right - right outline width (Float)
    # bottom - bottom outline width (Float)
    # left - left outline width (Float)
    #
    # Returns Hokusai::Outline
    def initialize(top, right, bottom, left)
      @top = top
      @left = left
      @right = right
      @bottom = bottom
    end
  
    # Public: Default outline - zero'ed out.
    #
    # Returns Hokusai::Outline
    def self.default
      new(0.0, 0.0, 0.0, 0.0)
    end

    def hash
      [self.class, top, right, bottom, left].hash
    end

    # Public: Converts value to outline
    #
    # value - value can be String of comma delimited float values (top, right, bottom, left)
    #         an Array of float values, a Hokusai::Outline value
    #         or an Float, which will be applied to uniformly
    #
    # Examples
    #
    #   Hokuasi::Outline.convert("1.0,0.0,1.0,0.0")
    #   # Hokusai::Outline(@top = 1.0, @right = 0.0, @bottom = 1.0, @left = 0.0)
    #
    # Returns Hokusai::Outline
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

    # Public: Does this outline have any widths above 0?
    #
    # Returns boolean
    def present?
      top > 0.0 || right > 0.0 || bottom > 0.0 || left > 0.0
    end

    def uniform?
      top == right && top == bottom && top == left
    end
  end

  class Boundary < Outline
  end

  # Public: Hokusai::Padding represents padding around a given geometry
  class Padding
    attr_reader :top, :left, :right, :bottom

    # Public: Constructor for Hokusai::Padding
    #
    # top - top outline width (Float)
    # right - right outline width (Float)
    # bottom - bottom outline width (Float)
    # left - left outline width (Float)
    #
    # Returns Hokusai::Padding
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

    # Public: The total width of the padding
    #
    # Returns Float
    def width
      right + left
    end

    # Public: The total height of the padding
    #
    # Returns Float
    def height
      top + bottom
    end

    # Public: Converts value to padding
    #
    # value - value can be String of comma delimited float values (top, right, bottom, left)
    #         an Array of float values, a Hokusai::Padding value
    #         or an Integer, which will be applied to uniformly
    #
    # Examples
    #
    #   Hokuasi::Padding.convert("22,22,22,22")
    #   # Hokusai::Padding(@top = 22, @right = 22, @bottom = 22, @left = 22)
    #
    # Returns Hokusai::Padding
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

  # Public: Hokusai::Canvas represents a drawable region
  # It provides information between Hokusai::Painter and a Hokusai::Block
  class Canvas
    # Public: Should the following blocks be vertical?
    #
    # value - true if vertical
    #
    # Returns Nothing
    attr_accessor :vertical

    attr_accessor :width, :height, :x, :y, :reverse, :offset_y
    attr_reader :ox, :oy, :owidth, :oheight

    # Internal: Constructor for Hokusai::Canvas
    # You should not need to use this
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

    # Public: Resets canvas at [x,y,width, height]
    #
    # x - x coordinate
    # y - y coordinate
    # width - width of canvas
    # height - height of canvas
    #
    # Returns Nothing
    def reset(x, y, width, height, vertical: true, reverse: false)
      self.x = x
      self.y = y
      self.width = width
      self.height = height
      self.vertical = vertical
      self.reverse = reverse
      self.offset_y = 0.0
    end

    # Public: Convert a canvas to a Hokusai::Rect
    #
    # Returns Hokusai::Rect
    def to_bounds
      Hokusai::Rect.new(x, y, width, height)
    end

    # Internal: Test if Mouse input is hovering this canvas
    #
    # input - a Hokusai::Input
    #
    # Returns boolean
    def hovered?(input)
      input.hovered?(self)
    end

    # Public: Are the following children of this Canvas reversed?
    #
    # Returns boolean
    def reverse?
      reverse
    end
  end

  # Public: Represents an RGBA color
  # 
  # Examples
  #
  #   Hokusai::Color.new(0,0,0,255)
  #   # black
  #
  #   Hokusai::Color.convert([255,0,0,100])
  #   # translucent red
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

    # Public: Converts value to Hokusai::Color
    #
    # value - value can be String of comma delimited integer values (red, green, blue, alpha)
    #         an Array of integer values, or a Hokusai::Color value
    #
    # Examples
    #
    #   Hokuasi::Color.convert("22,22,22,22")
    #   # Hokusai::Padding(@red = 22, @green = 22, @blue = 22, @alpha = 22)
    #
    # Returns Hokusai::Padding
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

    # Public: Converts to a value where each component is a number between 0 and 1
    # useful for fragment shaders
    #
    # Examples
    #
    #   Hokusai::Color.new(255,255,255,255).to_shader_value
    #   # [1.0,1.0,1.0,1.0]
    #
    # Returns Array(Float)
    def to_shader_value
      [(r / 255.0), (g / 255.0), (b / 255.0), (a / 255.0)]
    end

    def hash
      [self.class, r, g, b, a].hash
    end
  end
end
module Hokusai
  # Internal: tracks drag touch input state
  class Drag
    attr_accessor :pos, :angle
    def initialize
      @pos = Vec2.new(0.0, 0.0)
      @angle = 0
    end
  end

  class Pinch < Drag; end

  EVENTS = {
    0 => :none,
    1 => :tap,
    2 => :doubletap,
    4 => :hold,
    8 => :drag,
    16 => :swipe_right,
    32 => :swipe_left,
    64 => :swipe_up,
    128 => :swipe_down,
    256 => :pinch_in,
    512 => :pinch_out,
    1024 => :released,
  }

  # Internal: Touch management. Populated from MRuby/Raylib layer
  class Touch
    attr_accessor :type, :hold_duration, :drag, :pinch, :down, :up,
                  :pos, :count
    def initialize
      @type = :none
      @pos = Vec2.new(0.0, 0.0)
      @count = 0
      @hold_duration = 0.0
      @drag = Drag.new
      @pinch = Pinch.new
    end

    # Internal: Not touching?
    # 
    # Returns boolean
    def released?
      @type == :released || @type == :none
    end

    def set(event)
      @type = EVENTS[event]
    end

    EVENTS.values.each do |event|
      define_method("#{event}?") do
        @type == event
      end
    end
  end
end

module Hokusai
  # Public: Represenation of mouse button state
  #  
  # Examples
  # 
  #   # from input
  #   input.mouse.left.up # => false
  #   input.mouse.left.down # => true
  #   input.mouse.left.clicked # => true
  #   input.mouse.left.released # => false
  #   
  class MouseButton
    attr_accessor :up, :down, :clicked, :released

    def initialize
      @up = false
      @down = false
      @clicked = false
      @released = false
    end
  end

  # Public: Representation of mouse state
  class Mouse  
    # Public: A [Hokusai::Vec2](/api/Hokusai/Vec2) holding the mouse position
    attr_reader :pos

    # Public: A [Hokusai::Vec2](/api/Hokusai/Vec2) holding the mouse delta
    attr_reader :delta

    # Public: A float containing the mouse scroll
    attr_reader :scroll

    # Public: A float containing the mouse scroll delta
    attr_reader :scroll_delta

    attr_reader :left, :right, :middle

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

  # Internal: Represents keyboard state
  #           populated by the MRuby/Raylib backend.
  #           Should not need to use this directly.
  class Keyboard
    attr_accessor :shift, :control, :super, :alt
    attr_reader :keys, :pressed, :released, :down

    # Public: Is the pressed key printable?
    # 
    # Returns boolean
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
      @down = []

      KEY_CODES.each do |symbol, code|
        @keys[symbol] = { code: code, symbol: symbol, up: false, down: false, pressed: false, released: false }
      end
    end

    # Internal: The symbol form of the pressed key
    # 
    # Examples
    #  
    #   keyboard.symbol
    #   #=> :enter
    #   
    # Returns Symbol
    def symbol
      pressed[0]&.[](:symbol)
    end

    # Internal: The integer code form of the pressed key
    # 
    # Examples
    #  
    #   keyboard.symbol
    #   #=> 257
    #   
    # Returns Symbol
    def code
      pressed[0]&.[](:code)
    end

    # Internal: The char of the presed key
    # 
    # Returns String
    def char
      pressed[0]&.[](:char)
    end

    def ctrl
      @control
    end

    def reset
      @pressed.clear
      @released.clear
      @down.clear
      
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
        
        @pressed << nkey
      elsif down
        keys[key][:pressed] = false
        keys[key][:released] = false
        keys[key][:down] = true

        nkey = keys[key].dup
        nkey.merge!({ char: char_code_from_key(key, shift)&.chr })

        @down << nkey
      elsif !down && keys[key][:down]
        keys[key][:pressed] = false
        keys[key][:released] = true

        nkey = keys[key].dup
        nkey.merge!({ char: char_code_from_key(key, shift)&.chr })

        @released << nkey
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
  # Internal: Manages external input.  Populated from MRuby/Raylib backend
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

    # Internal: Collect touch input
    def support_touch!
      @touch ||= Touch.new

      self
    end

    # Internal: Keyboard input
    # 
    # Returns [Hokusai::Keyboard](/api/Hokusai/Keyboard)
    def keyboard
      @keyboard ||= Keyboard.new
    end

    # Internal: Mouse input
    # 
    # Returns [Hokusai::Mouse](/api/Hokusai/Mouse)
    def mouse
      @mouse ||= Mouse.new
    end

    # Internal: check if mouse is over (canvas)
    # 
    # canvas - a Hokusai::Canvas
    # 
    # Returns boolean
    def hovered?(canvas)
      pos = mouse.pos
      pos.x >= canvas.x && pos.x <= canvas.x + canvas.width && pos.y >= canvas.y && pos.y <= canvas.y + canvas.height
    end
  end
end

module Hokusai
  # Public: HTTP module used in [Hokusai::Block](/api/Hokusai/Block.html#fetch-url-opts-path-block)
  module HTTP
    # Public: Represents http response
    class ResponseBody
      attr_reader :finished, :tmp
      attr_accessor :value, :buffer

      def initialize
        @buffer = ""
        @value = ""
        @tmp = "#{Hokusai.tmpdir}/#{Hokusai.monotonic}"
        @finished = false
      end

      # Public: buffered read callback to pipe response data
      # 
      # block - the callback
      # 
      # Returns nothing
      def on_read(&block)
        io = File.open(@tmp, "r")
        io.each do |group|
          block.call(group)
        end

        io.close
      end
      
      # Internal: Writes content to this response's io
      # 
      # content - a string
      def write(content)
        @io ||= File.open(@tmp, "w")
        @io << content
      end

      # Internal: closes the io
      def finish
        @finished = true
        @io.close
      end

      # Public: Get the response body as a ruby object
      # 
      # Returns Object
      def json
        JSON.parse(all)
      end

      # Public: Get response body as a String
      # 
      # Returns String
      def all
        tmp = File.read(@tmp)

        IO.popen("rm #{@tmp}") if File.exist?(@tmp)

        tmp
      end
    end

    class Response
      attr_accessor :code, :status
      def initialize
        @code = nil
        @status = nil
        @body = ResponseBody.new
      end

      def body
        @body
      end
    end
  end
end

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

module Hokusai
  # Internal: Represents a patch to move a loop item
  #           from one location to another
  #           used in [Diff](/api/Hokusai/Diff)
  class MovePatch
    attr_accessor :from, :to, :value, :delete

    # Internal: MovePatch constructor
    # 
    # from: - kwarg index moving from
    # to: - kwarg index moving to
    # value: - kwarg value
    # delete: - should we overwrite to:?
    # 
    def initialize(from:, to:, value:, delete: false)
      @from = from
      @to = to
      @value = value
      @delete = delete
    end
  end

  # Internal: Represents a patch to insert an item into the loop list
  #           used in [Diff](/api/Hokusai/Diff)
  class InsertPatch
    attr_accessor :target, :value, :delete

    # Internal: InsertPatch constructor
    # 
    # target: - kwarg index to insert at
    # value: - kwarg value
    # delete: - should we overwrite the target?
    def initialize(target:, value:, delete: false)
      @target = target
      @value = value
      @delete = delete
    end
  end

  # Internal: Represents a patch to update the value of a loop item at an index
  #           used in [Diff](/api/Hokusai/Diff)
  class UpdatePatch
    attr_accessor :target, :value

    # Internal: constructor
    # 
    # target: - index to update
    # value: - value to update with
    def initialize(target:, value:)
      @target = target
      @value = value
    end
  end

  # Internal: Patch to delete a loop list item
  #           used in [Diff](/api/Hokusai/Diff)
  class DeletePatch
    attr_accessor :target

    # Internal: constructor
    # 
    # target - index to delete
    def initialize(target)
      @target = target
    end
  end

  # Internal: A Differ for comparing one set of values to another
  #           When #patch is called, will yield various patches to
  #           true up the old values with the new values.
  #           see: [MovePatch](/api/Hokusai/MovePatch), [InsertPatch](/api/Hokusai/InsertPatch), [UpdatePatch](/api/Hokusai/UpdatePatch), and [DeletePatch](/api/Hokusai/DeletePatch)
  class Diff
    attr_reader :before, :after, :insertions

    # Internal: constructor
    # 
    # before - array of before values
    # after - array of after values
    # 
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

    # Internal: yields a sequence of patches to make 
    #           before the same as after
    #
    # Returns nothing
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
    # Internal: Used to populate context vars from a template loop directive
    class LoopContext
      attr_reader :table, :proxies
      def initialize
        @table = {}
        @proxies = {}
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

    # Internal: Represents a looped AST node
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
        child_block_class = ast.dynamic? ? ast.type : target.class.use(ast.type)
        values = target.send(ast.loop.method)

        unless values.is_a?(Enumerable)
          raise Hokusai::Error.new("Loop directive `#{ast.loop.method}` on #{target.class} must return an Enumerable")
        end

        ast.loop.lastlen = values.size
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
              condition = ast.if.method.is_a?(Proc) ? target.instance_eval(&ast.if.method) : target.send(ast.if.method)
            end

            next if condition
          end

          portal = Node.new(ast)
          ctx.proxies[portal.ast.loop.proxy] = value

          node = child_block_class.compile(ast.type, portal)
          child_block = child_block_class.new(node: node, providers: mount_providers)
          child_block.node.add_styles(target.class)
          child_block.node.add_props_from_block(target, context: ctx)
          child_block.node.meta.set_prop(ast.loop.var.to_sym, value)
          child_block.node.meta.publisher.add(target, extra: ctx.proxies)

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

          raise Hokusai::Error.new("Loop children must have a :key prop defined") if key_prop.nil?

          key_ctx = LoopContext.new

          new_values = []

          index_key = "index".freeze
          values.each_with_index do |value, index|
            key_ctx.add_entry(ast.loop.var, value)
            key_ctx.add_entry(index_key, index)

            if key_prop.value.method.is_a?(Proc)
              ast.loop.proxy.value = value
              key = key_ctx.instance_eval(&key_prop.value.method)
            elsif key_prop.value.args.size > 0
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

          uchildren = ublock.node.meta.children![ast.loop.start, ast.loop.lastlen]

          uchildren.each do |child|
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
                  condition = ast.if.method.is_a?(Proc) ? target.instance_eval(&ast.if.method) : ctx.send_target(target, ast.if.method)
                else
                  condition = ast.if.method.is_a?(Proc) ? target.instance_eval(&ast.if.method) : target.send(ast.if.method)
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
              
              child_block_class = target_ast.dynamic? ? target_ast.type : utarget.class.use(target_ast.type)
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
              children[patch.target]&.send(:before_destroy) if children[patch.target]&.respond_to? :before_destroy
              children[patch.target]&.node&.destroy
              children[patch.target] = nil
              # TODO: update rest of block props
            end
          end

          ublock.node.add_styles(utarget.class)
          ublock.node.add_props_from_block(utarget)
          ublock.node.meta.children![ast.loop.start, ast.loop.lastlen] = children.reject(&:nil?)
          ast.loop.lastlen = children.reject(&:nil?).size
        end
      end
    end
  end
end
module Hokusai
  module Mounting
    # Internal: Represents a Block/template to be mounted
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
        klass = ast.dynamic? ? ast.type : target.class.use(ast.type)
        portal = Node.new(ast)

        # compile the ast and get the node
        # NOTE: for templates, we compile the ast before instatiation
        # but for build templates we need the block before the node.
        node = klass.compile(ast.type, portal)
        node.add_styles(target.class)
        node.add_props_from_block(target, context: context || ctx)

        # handle provides / dependency injection
        child_block = klass.new(node: node, providers: providers.merge(mount_providers))
        child_block.node.meta.publisher.add(target, extra: context&.proxies || ctx&.proxies || {}) # todo
        UpdateEntry.new(child_block, block, target).register(context: context || ctx, providers: providers.merge(mount_providers))

        block.node.meta << child_block

        yield child_block

        block.on_mounted if block.respond_to?(:on_mounted) if ast.siblingindex.zero?
      end
    end
  end
end
module Hokusai
  module Mounting
    # Internal: Holds update logic for a block/ast
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
                visible = child.if.proc? ? utarget.instance_eval(&child.if.method) : utarget.send(child.if.method, context: context)
              else
                visible = child.if.proc? ? utarget.instance_eval(&child.if.method) : utarget.send(child.if.method)
              end

              child_block_klass = child.dynamic? ? child.type : target.class.use(child.type)

              if !!visible
                if child.else_condition_active?
                  meta.child_delete(index) if child_present.call(child, false)
                  child.else_active = false
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

                  UpdateEntry.new(child_block, ublock, utarget).register(context: context, providers: providers)
                  meta.children!.insert(index, child_block)

                  child_block.send(:before_updated) if child_block.respond_to?(:before_updated)
                  Hokusai.update(child_block)
                  child.else_active = false
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
                  UpdateEntry.new(child_block, ublock, utarget).register(context: context, providers: providers)
                  meta.children!.insert(index, child_block)
                  child_block.send(:before_updated) if child_block.respond_to?(:before_updated)
                  
                  Hokusai.update(child_block)
                  child.else_active = true
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
  # Internal: Mounts a Hokusai::Block into a Hokusai::Node
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
          next unless (entry.ast.if.proc? ? entry.target.instance_eval(&entry.ast.if.method) : entry.target.send(entry.ast.if.method))
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
  # Internal: An event emitter
  class Publisher
    attr_reader :listeners

    def initialize(listeners = [])
      @listeners = listeners
    end

    # Internal: Adds a listener that subscribes to events emitted by this publisher
    #
    # listener - a Hokusai::Block
    def add(listener, extra: {})
      listeners << [listener, extra]
    end

    # Internal: emits `event` with `**args` to all subscribers
    #
    # name - event name
    # args - splatted arg array
    # kwargs - any kwargs to send
    def notify(name, *args, **kwargs)
      listeners.each do |(listener, extra)|
        raise Hokusai::Error.new("No target `##{name}` on #{listener.class}") unless name.is_a?(Proc) || listener.respond_to?(name)

        # for built asts
        if name.is_a?(Proc)
          extra.each do |proxy, value|
            proxy.value = value
          end

          listener.instance_exec(*args, **kwargs, &name)
        else
          listener.send(name, *args, **kwargs)
        end
      end
    end
  end
end

module Hokusai
  # Public: coordinates block children, including updates and event emitting
  # 
  class Meta
    attr_reader :focused, :parent, :target, :updater,
                :props, :publisher

    # Internal: a Hokusai::Commands cache
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

    # Internal: How many descedants does this node have?
    # 
    # returns Integer
    def node_count
      count = children?&.size || 0

      children?&.each do |child|
        count += child.node.meta.node_count
      end

      count
    end

    # Internal: Gets a child by index
    # 
    # index - the index of the child block (Integer)
    # 
    # Returns Hokusai::Block or nil
    def get_child?(index)
      return nil if @children.nil?

      get_child(index)
    end

    # Internal: Sets children
    # 
    # values - array of Hokusai::Block
    # 
    # Returns nothing
    def children=(values)
      @children = values
    end

    def children?
      return nil if @children.nil?

      @children
    end

    # Internal: Append child
    # 
    # child - a Hokusai::Block
    def <<(child)
      children! << child
    end
    
    # Internal: Gets a child by index.  Creates an empty array if no children found.
    # 
    # index - the index of the child block (Integer)
    # 
    # Returns Hokusai::Block
    def get_child(index)
      children![index]
    end

    # Public: Set a child by index. Creates an empty array if no children found.
    # 
    # index - the index of child block (Integer)
    # value - a Hokusai::Block
    # 
    # Returns nothing
    def set_child(index, value)
      children![index] = value
    end


    # Internal: Returns children or empty array
    def children!
      @children ||= []
    end

    # Internal: Returns props or empty hash
    def props!
      @props ||= {}
    end

    # Public: Get a prop value by it's name
    # 
    # name - name of prop (Symbol)
    # 
    # Returns Object or Nil if no props found
    def get_prop?(name)
      return nil if @props.nil?

      get_prop(name)
    end

    # Public: Set a prop value
    # 
    # name - name of prop (Symbol)
    # value - value to set prop to 
    def set_prop(name, value)
      @props ||= {}

      @props[name] = value
    end

    # Public: Get a prop value by it's name
    # 
    # name - name of prop (Symbol)
    # 
    # Returns Object or nil if prop not found
    def get_prop(name)
      @props ||= {}

      @props[name]
    end

    # Public: Set this node and chlidren to focused
    def focus
      @focused = true

      children?&.each do |child|
        child.node.meta.focus
      end
    end

    # Public: Unfocus this node and children
    def blur
      @focused = false

      children?&.each do |child|
        child.node.meta.blur
      end
    end

    # Internal: Set on update callback.  Used by [Hokusai::NodeMounter](/api/Hokusai/NodeMounter) and the like
    # 
    # target - a Hokusai::Block that this node should emit events to
    # block - an updater callback
    def on_update(target, &block)
      @target = target
      @updater = block
    end

    # Internal: Updates the props on (value), calling lifecycle callbacks if they exist.
    # 
    # value - a Hokusai::Block
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

    # Internal: Delete a child by index, calling lifecycle callbacks if they exist.
    # 
    # index - the index of the child
    # 
    # Returns nothing
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
  class NodeProxy
    def initialize
      @events = {}
    end

    def on(type, &block)
      @events[type] = block
    end
  end

  # Internal: Container for the AST, props, events, and children
  #           available on [Hokusai::Block#node](/api/Hokusai/Block#node)
  # 
  class Node
    attr_reader :ast, :node, :uuid, :meta, :portal

    def self.build(klass, parent = nil, &block)
      ast = NodeBuilder.build(klass, &block)

      new(ast, parent)
    end

    def self.parse(template, name = "root", parent = nil)
      ast = Ast.parse(template, name)

      new(ast, parent)
    end

    # Internal: Is this node a slot?
    # 
    # Returns boolean
    def slot?
      ast.slot?
    end

    # Internal: name of this node
    # 
    # Returns String
    def type
      ast.type
    end

    # Internal: Get a event by name (if one exists)
    # 
    # name - Name of the event
    # 
    # Returns [Hokusai::Ast::Event](/api/Hokusai/Ast/Event) or nil if none exists
    def event(name)
      ast.event(name)
    end

    def destroy; end

    def initialize(ast, portal = nil)
      @ast = ast
      @portal = portal
      # @uuid = SecureRandom.hex(6).freeze
      @meta = Meta.new
    end

    def mount(klass, providers: {})
      NodeMounter.new(self, klass, previous_providers: providers).mount
    end

    # Internal: Emit event to subscribers
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
            meta.set_prop(key.to_sym, value) unless value.nil?
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
                if method.is_a?(Proc)
                  if local_portal.ast.loop?
                    proxy = local_portal.ast.loop.proxy
                    proxy.value = context.table[local_portal.ast.loop.var]
                  end
                  value = block.instance_eval(&method)
                else
                  value = block.instance_eval(method)
                end
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
module Hokusai
  # Internal: An event emitter
  class Publisher
    attr_reader :listeners

    def initialize(listeners = [])
      @listeners = listeners
    end

    # Internal: Adds a listener that subscribes to events emitted by this publisher
    #
    # listener - a Hokusai::Block
    def add(listener, extra: {})
      listeners << [listener, extra]
    end

    # Internal: emits `event` with `**args` to all subscribers
    #
    # name - event name
    # args - splatted arg array
    # kwargs - any kwargs to send
    def notify(name, *args, **kwargs)
      listeners.each do |(listener, extra)|
        raise Hokusai::Error.new("No target `##{name}` on #{listener.class}") unless name.is_a?(Proc) || listener.respond_to?(name)

        # for built asts
        if name.is_a?(Proc)
          extra.each do |proxy, value|
            proxy.value = value
          end

          listener.instance_exec(*args, **kwargs, &name)
        else
          listener.send(name, *args, **kwargs)
        end
      end
    end
  end
end

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


class Hokusai::Commands
  # Internal: Base Command used by Hokusai::Commands to generate an ordered list of commands
  #           for the C/Raylib backend
  class Base
    # Internal: set drawing callback
    # 
    # block - drawing callback proc
    # 
    # Returns nothing
    def self.on_draw(&block)
      @draw = block
    end

    # Internal: get drawing callback
    # 
    # Returns Proc
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
  # Internal: Command to draw a circle.
  #           Radius starts from [x,y] and moves outward from center
  class Commands::Circle < Commands::Base
    attr_reader :x, :y, :radius, :color, :outline_color,
                :outline

    # Internal: Circle constructor
    # 
    # x - x coordinate
    # y - y coordinate
    # radius - circle radius
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

    # TODO: Give the circle an outline
    # @param [Float] outline weight
    def outline=(weight)
      @outline = weight

      self
    end

    # Public: sets the circle color.
    # 
    # value - a Hokusai::Color or Array of Int
    #
    # Returns nothing
    def color=(value)
      case value
      when Color
        @color = value
      when Array
        @color = Color.new(value[0], value[1], value[2], value[3] || 255)
      end

      self
    end

    # TODO: Give the circle an outline color
    # @param [Hokusai::Color | Array(Integer)] a Hokusai::Color or array of rgba values
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
  # Internal: Command to render an Hokusai::Image
  class Commands::Image < Commands::Base
    attr_reader :x, :y, :width, :height, :image, :slice

    # Internal: constructor
    # 
    # image - a Hokusai::Image
    # x - x coordinate
    # y - y coordinate
    # width - width (float)
    # height - height (float)
    def initialize(image, x, y, width, height)
      @image = image
      @x = x
      @y = y
      @width = width
      @height = height
      @slice = nil
    end

    # Public: Specify a slice of the image to render
    #         Useful for spritesheets
    #         
    # rect - a [Hokusai::Rect](/api/Hokusai/Rect) which denotes where to pick from the image
    # 
    # Returns nothing
    def slice=(rect)
      raise Hokusai::Error.new("Argument must be a Hokusai::Rect") unless rect.is_a? Hokusai::Rect

      @slice = rect
    end

    def hash
      [self.class, x, y, width, height].hash
    end

    def cache
      [width, height].hash
    end
  end
end

module Hokusai
  # Internal: Command to render a rectangle
  class Commands::Rectangle < Commands::Base
    attr_reader :x, :y, :width, :height,
                :rounding, :color, :outline,
                :outline_color, :padding, :gradient

    # @param [Float] start x
    # @param [Float] start y
    # @param [Float] rect width
    # @param [Float] rect height
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
        raise Hokusai::Error.new("Gradient must be an array of 4 Hokusai::Color")
      end

      @gradient = colors
    end

    # Public: Sets padding for the rectangle
    # 
    # value - a [Hokusai::Padding](/api/Hokusai/Padding) object
    # 
    # Returns self
    def padding=(value)
      case value
      when Padding
        @padding = value
      else
        @padding = Padding.convert(value)
      end

      self
    end

    # Public: Set outline for rect
    # 
    # value - a [Hokusai::Outline](/api/Hokusai/Outline) object
    def outline=(outline)
      @outline = outline

      self
    end

    # Public: Set outline color
    # 
    # value - a [Hokusai::Color](/api/Hokusai/Color) object
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

    # Public: Set fill color
    # 
    # value - a [Hokusai::Color](/api/Hokusai/Color) object
    # 
    # Returns self
    def color=(value)
      case value
      when Color
        @color = value
      when Array
        @color = Color.new(value[0], value[1], value[2], value[3] || 255)
      end

      self
    end

    # Public: sets rounding
    # 
    # amount - a float value between 0 and 1
    # 
    # Returns self
    def round=(amount)
      @rounding = amount

      self
    end

    # Public: returns true if the rectangle has any padding
    def padding?
      [padding.t, padding.r, padding.b, padding.l].any? do |p|
        p != 0.0
      end
    end


    def boundary
      [x, y, width, height]
    end

    # Public: get the rect dimensions after padding and outline applied
    # 
    # Returns Array(Float)
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

    # Public: Does this rect have any outlines?
    def outline?
      outline.present?
    end

    # Public: Is the rect outline uniform?
    def outline_uniform?
      outline.uniform?
    end
  end
end
module Hokusai
  # Starts a Scissor filter
  # Every command inside this filter
  # will apply the pruning area
  # This is useful for panels and scrollable areas
  class Commands::ScissorBegin < Commands::Base
    attr_reader :x, :y, :width, :height

    # @param [Float] start x
    # @param [Float] start y
    # @param [Float] scissor width
    # @param [Float] scissor height
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
                :font, :static, :line_height

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
      @line_height = 0.0
    end

    def hash
      [self.class, content, color.hash, padding.hash, size, font, wrap].hash
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

    # Sets the font
    # @param [Hokusai::Backend::Font] the font to render with
    def font=(value)
      @font = value
    end

    # Set content
    # @param [String] the content to render
    def content=(value)
      @content = value
    end

    # Sets the font size
    # @param [Integer] font size
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
  # Starts a Shader filter
  # Every command inside this filter
  # will be applied with this shader
  class Commands::ShaderBegin < Commands::Base
    attr_reader :vertex_shader, :fragment_shader, :uniforms

    def initialize
      @uniforms = {}
      @vertex_shader =  nil
      @fragment_shader = nil
      @textures = {}
    end

    # Set a Raylib style vertex shader
    # @param [String] vertex shader string
    def vertex_shader=(content)
      @vertex_shader = content
    end

    # Set a Raylib style vertex shader
    # @param [String] vertex shader string
    def fragment_shader=(content)
      @fragment_shader = content
    end

    # Set Uniforms to be used in the shaders
    # @param [Hash] a key value hash where 
    #   the key is a String with the uniform name
    #   the value is an array of [value, type]
    # Example:
    # command.uniforms = { "time" => [0.22, HP_SHADER_UNIFORM_FLOAT], "rgba" => [[0,0,0,244], HP_SHADER_UNIFORM_IVEC4]}
    def uniforms=(values)
      @uniforms = values
    end

    # Provide the shader with Hokusai::Textures
    # @param [Hash] a hash where
    #   the key is a String with the texture name
    #   the value is a Hokusai::Texture
    def textures=(values)
      @textures = values
    end

    def textures
      @textures.transform_keys(&:to_s)
    end

    def uniforms
      @uniforms.transform_keys!(&:to_s)
    end

    def hash
      [self.class, vertex_shader, fragment_shader].hash
    end
  end

  # Stops a shader filter
  class Commands::ShaderEnd < Commands::Base
    def hash
      [self.class].hash
    end
  end
end
module Hokusai
  # Internal: Command to draw a Hokusai::Texture
  class Commands::Texture < Commands::Base
    attr_reader :texture, :x, :y
    attr_accessor :width, :height, :flip, :repeat, :rotation

    def initialize(texture, x, y)
      @texture = texture
      @x = x
      @y = y
      @width = texture.width.to_f
      @height = texture.height.to_f
      @repeat = false
      @rotation = 0.0
      @flip = true
    end

    def hash
      [self.class, width, height].hash
    end
  end
end
module Hokusai
  # Internal: Starts a Rotation filter
  #           Every command inside this filter will be applied with the rotation
  class Commands::RotationBegin < Commands::Base
    attr_reader :x, :y, :degrees

    # Internal: constructor 
    # 
    # x - x rotation coord
    # y - y rotation coord
    # deg - degress to rotate
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
  # Starts a Scale filter
  # Every command inside this filter
  # will be scaled to [x,y]
  class Commands::ScaleBegin < Commands::Base
    attr_reader :x, :y

    # @param [Float] width of scale
    # @param [Float] height of scale
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
  # Command to perform a 2D Translation on
  # commands inside this filter
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

  # End the 2D Translation
  class Commands::TranslationEnd < Commands::Base;
    def hash
      [self.class].hash
    end
  end
end
module Hokusai
  # Internal: Starts a BlendMode filter where every command inside this filter
  #           will be applied with the selected blend mode
  class Commands::BlendModeBegin < Commands::Base
    attr_reader :type

    # Internal: constructor
    #   type - one of the values [:alpha, :multiply, :additive, :colors]
    def initialize(type)
      @type = type
    end

    def hash
      [self.class, type].hash
    end
  end

  # Internal: Stops a BlendMode filter
  class Commands::BlendModeEnd < Commands::Base;
    def hash
      [self.class].hash
    end
  end
end

module Hokusai
  # Public: A proxy class for invoking various UI commands
  #          Invocations of commands are immediately sent to the backend for drawing
  #          Used as part of the drawing api for Hokusai::Block
  class Commands
    attr_reader :queue

    def initialize
      @queue = []
    end

    def hash
      @queue.hash
    end

    # Public: Draw a rectangle.  Yields a [Commands::Rectangle](/api/Hokusai/Commands/Rectangle)
    #
    # x - the x coordinate
    # y - the y coordinate
    # width - the width of the rectangle
    # height - height of the rectangle
    # 
    def rect(x, y, w, h)
      command = Commands::Rectangle.new(x, y, w, h)

      yield(command)

      queue << command
    end

    # Public: Draw a circle.  Yields a [Commands::Circle](/api/Hokusai/Commands/Circle)
    #
    # x - x coordinate (Float)
    # y - y coordinate (Float)
    # radius - radius of the circle (Float)
    def circle(x, y, radius)
      command = Commands::Circle.new(x, y, radius)

      yield(command)

      queue << command
    end

    # Public: Draws an image.  Yields a [Commands::Image](/api/Hokusai/Commands/Image)
    # 
    # image - a Hokusai::Image
    # x - x coordinate (Float)
    # y - y coordinate (Float)
    # width - width (Float)
    # height - height (Float)
    def image(source, x, y, w, h)
      command = Commands::Image.new(source, x, y, w, h)

      yield(command) if block_given?

      queue << command
    end

    # Public: Starts a scissor region
    # 
    # x - x coordinate (Float)
    # y - y coordinate (Float)
    # width - width (Float)
    # height - height (Float)
    def scissor_begin(x, y, w, h)
      queue << Commands::ScissorBegin.new(x, y, w, h)
    end

    # Public: ends scissor region
    def scissor_end
      queue << Commands::ScissorEnd.new
    end

    # Public: starts blend mode 
    # 
    # type - one of the values [:alpha, :multiply, :additive, :colors]
    def blend_mode_begin(type)
      queue << Commands::BlendModeBegin.new(type)
    end

    # Public: ends blend mode
    def blend_mode_end
      queue << Commands::BlendModeEnd.new
    end

    # Public: starts a GLSL shader.  Yields a [Commands::ShaderBegin](/api/Hokusai/Commands/ShaderBegin)
    def shader_begin
      command = Commands::ShaderBegin.new

      yield command

      queue << command
    end

    # Public: ends a shader
    def shader_end
      queue << Commands::ShaderEnd.new
    end

    # Public: starts a rotation
    # 
    # x - x coordinate (Float)
    # y - y coordinate (Float)
    # deg - degress to rotate (Integer)
    def rotation_begin(x, y, deg)
      queue << Commands::RotationBegin.new(x, y, deg)
    end

    # Public: ends a rotation
    def rotation_end
      queue << Commands::RotationEnd.new
    end

    # Public: starts a scale command
    def scale_begin(*args)
      queue << Commands::ScaleBegin.new(*args)
    end

    # Public: ends scaling
    def scale_end
      queue << Commands::ScaleEnd.new
    end

    # Public: Starts a 2D translation
    # x - x coordinate (Float)
    # y - y coordinate (Float)
    def translation_begin(x, y)
      queue << Commands::TranslationBegin.new(x, y)
    end

    # Public: Ends a 2D translation
    def translation_end
      queue << Commands::TranslationEnd.new
    end

    # Public: Draws a texture
    # 
    # texture - A Hokusai::Texture
    # x - x coordinate (Float)
    # y - y coordinate (Float)
    def texture(texture, x, y)
      command = Commands::Texture.new(texture, x, y)

      yield command if block_given?

      queue << command
    end

    # Public: Draws text.  Yields a [Commands::Text](/api/Hokusai/Commands/Text)
    #
    # content - the text content
    # x - x coord (Float)
    # y - y coord (Float)
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
  # Public: A global registry for storing Hokusai::Music
  class MusicRegistry
    def initialize
      @musics = {}
    end

    # Public: Registers a Hokusai::Music on (name)
    # 
    # name - key to reference this music (String)
    # music - a Hokusai::Music instance
    def register(name, music)
      @musics[name] = music
    end

    # Public: fetches a music by name
    # 
    # name - key that references a Hokusai::Music
    # 
    # Returns Hokusai::Music
    def get(name)
      @musics[name]
    end

    # Public: delete a music by name
    # 
    # name - key that references a Hokusai::Music
    def delete(name)
      @musics.delete(name)
    end
  end

  # Public: A global registry for storing Hokusai::Texture
  class TextureRegistry
    attr_reader :textures

    def initialize
      @textures = {}
    end

    # Public: create a new texture and add it to the registry
    # 
    # name - key for texture (String)
    # width - width (Float)
    # height - height (Float)
    # 
    # Returns Hokusai::Texture
    def create(name, width, height)
      @textures[name] ||= Hokusai::Texture.init(width, height)
      @textures[name]
    end

    # Public: Registers a texture
    # 
    # name - key for texture (String)
    # texture - a Hokusai::Texture
    # 
    # Returns nothing
    def register(name, texture)
      @textures[name] = texture
    end

    # Public: Fetches a texture from the registry
    # 
    # name - key for texture (String)
    # 
    # Returns Hokusai::Texture
    def get(name)
      @textures[name]
    end

    # Public: Delete a texture from the registry
    # 
    # name - key for texture (String)
    # 
    # Returns nothing
    def delete(name)
      @textures.delete(name)
    end
  end

  # Public: A global registry for storing Hokusai::Image
  class ImageRegistry
    def initialize
      @images = {}
    end

    # Public: create a new image and add it to the registry
    # 
    # name - key for image (String)
    # width - width (Float)
    # height - height (Float)
    # transparent - make the image transparent (default: false)
    # 
    # Returns Hokusai::Image
    def create(name, width, height, transparent = false)
      @images[name] ||= Hokusai::Image.init(width, height, transparent)
      @images[name]
    end

    # Public: Registers an image
    # 
    # name - key for image (String)
    # image - a Hokusai::Image
    # 
    # Returns nothing
    def register(name, image)
      @images[name] = image
    end

    # Public: Fetches an image from the registry
    # 
    # name - key for image (String)
    # 
    # Returns Hokusai::Image
    def get(name)
      @images[name]
    end

    # Public: Delete a image from the registry
    # 
    # name - key for image (String)
    # 
    # Returns nothing
    def delete(name)
      @images.delete(name)
    end
  end

  # Public: A global registry for storing Hokusai::Backend::Font
  class FontRegistry
    attr_reader :fonts, :active_font

    def initialize
      @fonts = {}
      @active_font = nil
    end

    # Public: Registers a font
    #
    # name - font name
    # font - a Hokusai::Backend::Font
    def register(name, font)
      raise Hokusai::Error.new("Font #{name} already registered") if fonts[name]

      fonts[name] = font
    end

    # Public: Returns the active font's name
    #
    # Returns String
    def active_font_name
      raise Hokusai::Error.new("No active font") if active_font.nil?

      active_font
    end

    # Public: Activates a font by name
    #
    # name - the font name
    # 
    def activate(name)
      raise Hokusai::Error.new("Font #{name} is not registered") unless fonts[name]

      @active_font = name
    end

    # Public: Fetches a font
    #
    # name - the name of the registered font
    # 
    # Returns Hokusai::Backend::Font or nil
    def get(name)
      fonts[name]
    end

    # Public: Fetches the active font
    #
    # Returns a Hokusai::Backend::Font or nil
    def active
      fonts[active_font]
    end
  end
end
module Hokusai
  # Internal: A UI input event used in [Hokusai::Painter](/api/Hokusai/Painter)
  class BaseEvent
    attr_reader :captures
    attr_accessor :stopped

    # Internal: Sets the name of this event kind
    #  
    # name - event name (String)
    # 
    def self.name(name)
      @name = name
    end

    def name
      self.class.instance_variable_get("@name")
    end

    # Internal: adds evented styles to this block
    # 
    # value - a Hokusai::Block 
    #
    def add_evented_styles(block)
      if target = block.node.meta.target
        block.node.add_evented_styles(target.class, name)
      end
    end

    # Internal: capture a block
    # 
    # value - a Hokusai::Block
    def add_capture(block)
      captures << block
    end

    # Internal: Has the event stopped propagation?
    # 
    # Returns boolean
    def stopped
      @stopped ||= false
    end

    # Public: Stop the event from bubbling
    # 
    # Returns nothing
    def stop
      self.stopped = true
    end

    # Internal: All captures for this event
    # 
    # Returns Array(Hokusai::Block)
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

    # Internal: Does the event match the provided Hokusai::Block template?
    #
    # value - a Hokusai::Block
    # 
    # Returns boolean
    def matches(block)
      return false if block.node.portal.nil?

      val = block.node.portal.ast.event(name)

      !!val
    end

    # Internal: Emit the event to all captured blocks,
    #           stopping if any of the blocks stop propagation
    def bubble
      while block = captures.pop
        block.emit(name, self)
        break if stopped
      end
    end
  end
end

module Hokusai
  # Public: Represents a Keyboard Event
  class KeyboardEvent < BaseEvent
    attr_reader :input

    def initialize(input, state)
      @input = input
      @state = state
      @keyboard = input.keyboard
    end

    # Public: is the key printable to the screen?
    # 
    # Returns boolean
    def printable?
      @keyboard.printable?
    end
    
    # Public: array of pressed keys
    # 
    # Returns Array(Hash)
    def pressed
      @keyboard.pressed
    end

    # Public: array of released keys
    # 
    # Returns Array(Hash)
    def released
      @keyboard.released
    end

    # Public: array of keys currently being held down
    # 
    # Returns Array(Hash)
    def down
      @keyboard.down
    end

    # Public: the pressed/released character
    # 
    # Returns String
    def char
      @keyboard.char
    end
    
    # Public: the pressed/released key symbol
    # 
    # Returns Symbol
    def symbol
      @keyboard.symbol
    end

    # Public: the pressed/released key code
    # 
    # Returns Integer
    def code
      @keyboard.code
    end

    # Public: shift being pressed/released?
    # 
    # Returns boolean
    def shift
      @keyboard.shift
    end

    # Public: is super being pressed/released?
    # 
    # Returns boolean
    def super
      @keyboard.send(:super)
    end

    # Public: is ctrl being pressed/released?
    #
    # Returns boolean
    def ctrl
      @keyboard.ctrl
    end

    # Public: is alt being pressed/released?
    #
    # Returns boolean
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

  # Public: A [Hokusai::KeyboardEvent](/api/Hokusai/KeyboardEvent) where a key has been released.
  # 
  class KeyUpEvent < KeyboardEvent
    name "keyup"

    # Public: The released key in symbol from
    #
    # Returns Symbol
    def key
      released[0]&.[](:symbol)
    end

    # Public: the pressed/released key code
    # 
    # Returns Integer
    def code
      released[0]&.[](:code)
    end

    # Public: the pressed/released character
    # 
    # Returns String
    def char
      released[0]&.[](:char)
    end

    def capture(block, canvas)
      add_capture(block) if matches(block) && released.size > 0
    end
  end

  # Public: A [Hokusai::KeyboardEvent](/api/Hokusai/KeyboardEvent) where a key is being pressed.
  # 
  class KeyDownEvent < KeyboardEvent
    name "keydown"
    
    # Public: The key in symbol from
    #
    # Returns Symbol
    def key
      down[0]&.[](:symbol)
    end

    # Public: the key code
    # 
    # Returns Integer
    def code
      down[0]&.[](:code)
    end

    # Public: the character
    # 
    # Returns String
    def char
      down[0]&.[](:char)
    end

    def capture(block, _)
      return unless matches(block) && down.size > 0
      
      add_capture(block)
    end
  end

  # Public: A [Hokusai::KeyboardEvent](/api/Hokusai/KeyboardEvent) where a key has been pressed/released.
  # 
  class KeyPressEvent < KeyboardEvent
    name "keypress"

    # Public: The key in symbol from
    #
    # Returns Symbol
    def key
      pressed[0]&.[](:symbol)
    end

    # Public: the key code
    # 
    # Returns Integer
    def code
      pressed[0]&.[](:code)
    end

    # Public: the character
    # 
    # Returns String
    def char
      pressed[0]&.[](:char)
    end

    def capture(block, _)
      return unless matches(block) && pressed.size > 0
      add_capture(block)
    end
  end
end
module Hokusai
  # An class representing a Mouse event
  class MouseEvent < BaseEvent
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

    # Public: the x,y coordinates of the mouse
    # 
    # Returns Hokusai::Vec2
    def pos
      mouse.pos
    end

    # Public: the x,y delta coordinates
    # 
    # Returns Hokusai::Vec2
    def delta
      mouse.delta
    end

    # Public: the scroll amount
    # 
    # Returns Float
    def scroll
      mouse.scroll
    end

    # Public: the scroll delta value
    # 
    # Returns Float
    def scroll_delta
      mouse.scroll_delta
    end

    # Public: the details of the left mouse button
    # 
    # Returns [Hokusai::MouseButton](/api/Hokusai/MouseButton)
    def left
      @left
    end

    # Public: the details of the middle mouse button
    # 
    # Returns [Hokusai::MouseButton](/api/Hokusai/MouseButton)    
    def right
      @right
    end

    # Public: the details of the right mouse button
    # 
    # Returns [Hokusai::MouseButton](/api/Hokusai/MouseButton)    
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

  # Triggered when a mouse move occurs
  class MouseMoveEvent < MouseEvent
    name "mousemove"

    # Captured if the block is listening for @mousemove
    def capture(block, canvas)
      add_evented_styles(block) if hovered(canvas)

      if matches(block)
        add_capture(block)
      end
    end
  end

  # Public: Triggered when left mouse click occurs
  class ClickEvent < MouseEvent
    name "click"

    # Internal: Captured if the block is listening for @click 
    #           and the left mouse clicks the block geometry
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

  # Public: Triggered when left mouse button is up
  class MouseUpEvent < MouseEvent
    name "mouseup"

    def capture(block, canvas)
      add_evented_styles(block) if left.up && hovered(canvas)

      if left.up && matches(block)
        add_capture(block)
      end
    end
  end

  # Public: Triggered when left mouse button is down
  class MouseDownEvent < MouseEvent
    name "mousedown"

    def capture(block, canvas)
      add_evented_styles(block) if left.down && hovered(canvas)

      if left.down && matches(block)
        add_capture(block)
      end
    end
  end

  # Public: Triggered when mouse wheel is scrolled
  class WheelEvent < MouseEvent
    name "wheel"

    def capture(block, canvas)
      add_evented_styles(block) if scroll_delta != 0.0

      if matches(block) && scroll_delta != 0.0
        add_capture(block)
      end
    end
  end

  # Public: Triggered when mouse cursor is over a block
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

  # Public: Triggered when mouse cursor leaves a block
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

module Hokusai
  # Parent class representing a generic touch event
  class TouchEvent < BaseEvent
    attr_reader :input

    def initialize(input, state)
      @input = input
      @state = state
      @touch = input.touch
    end

    # Are there any touches?
    # @return [Bool]
    def down?
      @touch.count > 0
    end

    # Are there <not> any touches?
    # @return [Bool]
    def up?
      @touch.count <= 0
    end

    # @return [Bool] did a touch stop?
    def released?
      @touch.released?
    end

    def tapped?
      @touch.tap?
    end

    def doubletapped?
      @touch.doubletap?
    end

    def swiped_right?
      @touch.swipe_right?
    end

    def swiped_up?
      @touch.swipe_up?
    end

    def swiped_left?
      @touch.swipe_left?
    end

    def swiped_down?
      @touch.swipe_down?
    end

    def swipe_direction
      case @touch.type
      when :swipe_left
        :left
      when :swipe_right
        :right
      when :swipe_up
        :up
      when :swipe_down
        :down
      end
    end

    def pinch_direction
      case @touch.type
      when :pinch_in
        :in
      when :pinch_out
        :out
      end
    end

    def pinched?
      pinch_direction == :in || pinch_direction == :out
    end

    def swiped?
      swiped_right? || swiped_left? || swiped_up? || swiped_down?
    end

    def hold?
      @touch.hold?
    end
    
    def duration
      @touch.hold_duration
    end

    def pos
      @touch.pos
    end

    def drag
      @touch.drag
    end

    def pinch
      @touch.pinch
    end

    def hovered(canvas)
      pos = @touch.pos
      pos.x >= canvas.x && pos.x <= canvas.x + canvas.width && pos.y >= canvas.y && pos.y <= canvas.y + canvas.height
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

  class TapEvent < TouchEvent
    name "tap"

    def capture(block, canvas)
      if matches(block) && (tapped? || doubletapped?) && hovered(canvas)
        captures << block
      end
    end
  end
  
  class TapDownEvent < TouchEvent
    name "tapdown"

    def capture(block, canvas)
      if matches(block) && down? && hovered(canvas)
        captures << block
      end
    end
  end
    
  class TapUpEvent < TouchEvent
    name "tapup"

    def capture(block, canvas)
      if matches(block) && up? && hovered(canvas)
        captures << block
      end
    end
  end

  class TapReleaseEvent < TouchEvent
    name "taprelease"

    def capture(block, canvas)
      if matches(block) && released? && hovered(canvas)
        captures << block
      end
    end
  end

  class DoubletapEvent < TouchEvent
    name "doubletap"

    def capture(block, canvas)
      if matches(block) && doubletapped? && hovered(canvas)
        captures << block
      end
    end
  end

  class DragEvent < TouchEvent
    name "drag"

    def capture(block, canvas)
      if matches(block) && @touch.drag? && hovered(canvas)
        captures << block
      end
    end
  end

  class TapHoldEvent < TouchEvent
    name "taphold"

    def capture(block, canvas)
      if matches(block) && hold? && hovered(canvas)
        captures << block
      end
    end
  end

  class PinchOutEvent < TouchEvent
    name "pinchout"

    def capture(block, canvas)
      if pinch_direction == :out && matches(block) && hovered(canvas)
        captures << block
      end
    end
  end

  class PinchInEvent < TouchEvent
    name "pinchin"

    def capture(block, canvas)
      if pinch_direction == :in && matches(block) && hovered(canvas)
        captures << block
      end
    end
  end

  class SwipeEvent < TouchEvent
    name "swipe"

    def capture(block, canvas)
      if swiped? && matches(block) && hovered(canvas)
        captures << block
      end
    end
  end
end
module Hokusai
  # Internal: Describes a Block with layout coordinates for rendering
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

  # Internal: Responsible for iterating through the render tree, event handling, and invoking the draw callbacks
  #           Used by the C/MRuby backend
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
        keypress: KeyPressEvent.new(input, state),
        keydown: KeyDownEvent.new(input, state),
      }

      add_touch_events(events, input, state) unless input.touch.nil?
    end

    def add_touch_events(events, input, state)
      events.merge!({
        tap: TapEvent.new(input, state),
        drag: DragEvent.new(input, state),
        doubletap: DoubletapEvent.new(input, state),
        taphold: TapHoldEvent.new(input, state),
        pinchin: PinchInEvent.new(input, state),
        pinchout: PinchOutEvent.new(input, state),
        swipe: SwipeEvent.new(input, state),
        taprelease: TapReleaseEvent.new(input, state),
        tapdown: TapDownEvent.new(input, state),
        tapup: TapUpEvent.new(input, state),
      })
    end

    def on_before_render(&block)
      @before_render = block
    end

    def on_after_render(&block)
      @after_render = block
    end

    # Internal: Render the block on this painter in (canvas)
    # 
    # canvas - a Hokusai::Canvas to render on
    # resize - boolean telling us if this frame is resized
    # capture: - kwarg telling us if we should capture events
    # 
    # Returns nothing
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

      # root_children = (canvas.reverse? ? root.children?&.reverse.dup : root.children?&.dup) || []
      groups = []
      root_entry = PainterEntry.new(root, canvas.x, canvas.y, canvas.width, canvas.height)
      groups << [root_entry, measure([root], canvas)]

      unless input.touch
        mouse_y = input.mouse.pos.y
        can_capture = mouse_y >= (canvas.y || 0.0) && mouse_y <= (canvas.y || 0.0) + canvas.height
      else
        can_capture = true
      end

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

          if resize
            group.block.on_resize(canvas)
          end

          breaked = false

          group.block.render(canvas) do |local_canvas|
            # defer capture for zindexed items so they can stop propagation.
            if capture && (zindex_counter.zero? && z.zero?)
              capture_events(group.block, local_canvas, hovered: hovered)
            # since evented styles happens during capture and z-index skips capture, well add some
            elsif capture && !input.touch && input.hovered?(local_canvas)
              if target = group.block.node.meta.target
                group.block.node.add_evented_styles(target.class, "hover")
              end
            end

            local_children = (local_canvas.reverse? ? group.block.children?&.reverse : group.block.children?)

            unless local_children.nil?
              groups << [group_parent, group_children]
              parent = PainterEntry.new(group.block, canvas.x, canvas.y, canvas.width, canvas.height)
              wrap = group.block.node.meta.get_prop(:wrap) || false

              groups << [parent, measure(local_children, local_canvas, wrap: wrap)]

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
        events[:keydown].bubble

        unless input.touch.nil?
          events[:tap].bubble
          events[:doubletap].bubble
          events[:drag].bubble
          events[:taphold].bubble
          events[:pinchin].bubble
          events[:pinchout].bubble
          events[:swipe].bubble
          events[:taprelease].bubble
          events[:tapdown].bubble
          events[:tapup].bubble
        end
      end

      after_render&.call
    end

    def resolve_percent(value, total)
      return nil if value.nil?
      str = value.to_s
      if str.end_with?("%")
        (str[0...-1].to_f / 100.0) * total
      else
        str.to_f
      end
    end

    def measure(children, canvas, wrap: false)
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

        w = resolve_percent(w, width)
        h = resolve_percent(h, height)

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
        w = block.node.meta.get_prop?(:width)&.to_f || neww
        h = block.node.meta.get_prop?(:height)&.to_f || newh

        if wrap && x >= width
          y += h
          x = canvas.x
        end

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
      
      events[:keydown].capture(block, canvas)

      if !input.touch
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
      end

      unless input.touch.nil?
        events[:click].capture(block, canvas)
        events[:keyup].capture(block, canvas)
        events[:keypress].capture(block, canvas)
        events[:doubletap].capture(block, canvas)
        events[:tap].capture(block, canvas)
        events[:tapdown].capture(block, canvas)
        events[:taprelease].capture(block, canvas)
        events[:tapup].capture(block, canvas)
        events[:drag].capture(block, canvas)
        events[:taphold].capture(block, canvas)
        events[:pinchin].capture(block, canvas)
        events[:pinchout].capture(block, canvas)
        events[:swipe].capture(block, canvas)
      end
    end
  end
end

module Hokusai
  class TexturePainter
    attr_reader :root, :commands

    def initialize(root)
      @root = root
      @commands = []
    end

    # @return [Array(Commands::Base)] the command list
    def render(canvas)
      return if root.children.empty?

      zindexed = {}
      zindex_counter = 0

      zroot_x = canvas.x
      zroot_y = canvas.y
      zroot_w = canvas.width
      zroot_h = canvas.height

      root_children = (canvas.reverse? ? root.children?&.reverse.dup : root.children?&.dup) || []
      groups = []
      root_entry = PainterEntry.new(root, canvas.x, canvas.y, canvas.width, canvas.height)
      groups << [root_entry, measure([root], canvas)]

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
            zindexed[zindex_counter] << group
          else
            commands.concat group.block.node.meta.commands.queue
            group.block.node.meta.commands.clear!
          end

          break if breaked
        end
      end

      zindexed.sort.each do |z, groups|
        groups.each do |group|
          canvas.reset(group.x, group.y, group.w, group.h)

          commands.concat group.block.node.meta.commands.queue
          group.block.node.meta.commands.clear!
        end
      end
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
      @start_y = 0.0        # the y coordinate for the geometry 
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
  class Selection
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
  # Public: Payload for [Hokusai::Util::WrapStream#on_text](/api/Hokusai/Util/WrapStream.html#on-text-block)
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

  # Public: A cache that stores the results of WrapStream.
  #         Utiltiy methods are provided to quickly fetch a subset of tokens
  #         Based on a given window's coordinates (canvas)
  class WrapCache
    attr_accessor :tokens

    # Public: returns range denoting the index of the changed lines
    #         from 2 different strings.
    #         NOTE: the change must be consecutive
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

    # Public: Adds a token
    # 
    # token - Hokusai::Util::Wrapped 
    # 
    # Returns nothing
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

    # Public: Gets the area coordinates for a selection
    #         to draw a text selection background.
    # 
    # tokens - the result of WrapCache#tokens_for
    # selector - a [Hokusai::Util::Selection](/api/Hokusai/Util/Selection) object
    # options - kwargs options
    #           copy - boolean to copy selected tokens
    #           padding - a Hokusai::Padding object
    #           
    # Returns Hokusai::Util::WrapCachePayload
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

    # Public: Get cached tokens for a given Hokusai::Canvas
    # 
    # canvas - a Hokusai::Canvas
    # 
    # Return Array(Hokusai::Util::Wrapped)
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

  # Public: A disposable streaming text wrapper
  #         tokens can be appended onto it, where it they will break on a given width.
  #         Opaque payloads can be passed for each token, which will be provided to callbacks.
  #         This makes it suitable for processing and wrapping markdown/html/tokenized text
  #
  # Examples
  # 
  #   stream = Hokusai::Util::WrapStream.new(canvas.width, canvas.x, canvas.y) do |string, extra|
  #     # String is the data being wrapped
  #     # Extra is the payload provided for that string
  #     # Callbacks takes a [width, height] as response
  #     [Hokusai.fonts.get("default").measure(string, size).first, size]
  #   end
  #   #
  #   # subscribe to emitted tokens Hokusai::Util::Wrapped
  #   stream.on_text do |wrapped|
  #     draw do
  #       text(wrapped.text, wrapped.x, wrapped.y) do |command|
  #         command.color = wrapped.extra[:color]
  #       end
  #     end
  #   end
  #   # Feed the stream content
  #   stream.wrap("Hello this red text might be wrapped over the width", { color: Hokusai::Color.new(222,22,22) })
  #   stream.wrap("This is blue text", { color: Hokusai::Color.new(22,22,222) })
  #   # flush remaining tokens
  #   stream.flush
  #   # stream#y now holds the total height of the wrapped tokens
  #   stream.y
  #
  class WrapStream
    attr_accessor :buffer, :x, :y, :origin_y, :current_width, :stack, :widths, :current_position, :positions, :on_text_cb
    attr_reader :width, :origin_x, :on_text_cb

    # Public: constructor for WrapStream
    # 
    # width - a float. When text exceeds this width, it will wrap to a new line
    # origin_x - where the x value starts (default: 0.0)
    # origin_y - where the y value starts (default: 0.0)
    # block - a callback to measure a given string.  Callback must return an array containing the width and height of the string
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

    # Public: Appends (text) to the wrap stream.
    #         If the text supplies causes the buffer to grow beyond the supplied width
    #         The buffer will be flushed to the (on_text_cb) callback.
    #
    # text - text to append to this wrap stream
    # extra - an opaque payload that will be passed to callbacks
    # 
    # Returns nothing
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

    # Public: Flushes the current buffer/stack.
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

    # Public: A callback that is called whenever the stream is wrapped or flushes
    # 
    # block - the provided callback
    # 
    # Returns nothing
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

# Flags to pass to Hokusai::Backend::Config
# Example:
# ```ruby
# Hokusai::Backend.run(App) do |config|
#   config.config_flags = HP_FLAG_WINDOW_RESIZABLE | HP_FLAG_VSYNC_HINT
# end
# ```
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
  # A class for traversing a hokusai-pocket project
  # Yields every file that's required (depth-first)
  class Reloader
    def initialize(file_path, document = File.read(file_path))
      @file_path = file_path
      @document = document        
    end

    def traverse(&block)
      file_path_dir = File.dirname(@file_path)

      @document.gsub(/(?:require_relative\s+["'](.*)["'])/) do |path|
        base_path = Pathname.new(@file_path)
        path = Pathname.new("#{path.gsub(/require_relative\s+["']/, "").chop}.rb")
        resolved_path = Pathname.join(File.dirname(base_path.to_s), path).to_s

        block.call resolved_path

        Reloader.new(resolved_path).traverse(&block)
      end
    end
  end

  # Public: Runs a [Hokusai::Block](/api/Hokusai/Block) as a Game / Application
  #         Used by the C/MRuby/Raylb backend
  #
  # Examples
  #
  # Hokusai::Backend.run(BonziBuddy) do |config|
  #   config.title = "BonziBuddy reloaded"
  #   config.width = 500
  #   config.height = 500
  #   #
  #   # need to set at least one font if using text
  #   config.after_load do
  #     Hokusai.fonts.register "default", Hokusai::Backend::Font.default
  #     Hokusai.fonts.activate "default"
  #   end
  # end
  class Backend
    def self.htop  
      @running = true
      binding
    end

    # Public: Run a hokusai-pocket app.  Blocking until app is exited.
    #
    # klass - a Hokusai::Block.class
    # block - a callback to configure the application
    def self.run(klass, &block)
      return if @running
      config = Backend::Config.new
      block.call config

      obj = new(klass, config)
      obj.run
    end

    attr_reader :app, :config

    # Internal: constructor for Backend
    # 
    # app - a Hokusai::Block.class
    # config - a Hokusai::Backend::Config
    def initialize(app, config)
      @app = app
      @config = config
    end

    # Public: Configure the properties of a hokusai pocket app
    #         Set config flags, fps, title, and register assets.
    #         Passed as a callback parameter to [Hokusai::Backend.run](/api/Hokusai/Backend#run)
    class Config
      # Public: Set the width of the window on load
      #
      # value - The window pixel width (Integer)
      attr_accessor :width

      # Public: Set the height of the window on load
      #
      # value - The window pixel height (Integer)
      attr_accessor :height

      # Public: Set the desired frame rate (frames per second)
      #
      # value - The frames per second (Integer)
      attr_accessor :fps

      # Public: Set the title of the window
      #
      # value - The title of the window (String)
      attr_accessor :title

      # Public: Set any config flags for the window
      #
      # value - A union of HP_FLAG_*
      #
      # Examples
      #
      #   Hokusai::Backend.run(App) do |config|
      #     config.config_flags = HP_FLAG_VSYNC_HINT | HP_FLAG_WINDOW_RESIZABLE
      #   end
      #   # configures window to be resizable and sync frame rate with monitor
      attr_accessor :config_flags

      # Public: Set if application should pause rendering until an event comes through
      #
      # value - a boolean (false to turn off event waiting)
      attr_accessor :event_waiting

      # Public: Set if the application should draw the FPS in the top left corner
      #
      # value - true to draw FPS
      attr_accessor :draw_fps

      # Public: Set if the application should log to stdout
      #         Note LOG_LEVEL env var can be set to filter logging
      #
      # value - true to log
      attr_accessor :log

      # Public: Accessor to toggle audio (default false)
      #
      # value - true to use audio
      attr_accessor :audio

      # Public: Accessor to toggle touch input handling (default false)
      #
      # value - true to use touch events
      attr_accessor :touch

      attr_accessor :window_state_flags,
                  :automation_driver, :background, :after_load_cb,
                  :host, :port, :automated, :on_reload_proc

      def initialize
        @width = 500
        @height = 500
        @fps = 60
        @audio = true
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
        @on_reload_proc = nil
        @event_waiting = true
        @touch = false
        @log = false
      end

      # Internal: Not implemented
      def start_automation_driver
        raise ConfigError.new("Need a Hokusai::Driver in order to automate") if automation_driver.nil?

        automation_driver.serve(host, port)
      end

      # Internal: Not implemented
      def automate(host, port)
        self.host = host
        self.port = port
        self.automated = true
      end

      # Public: Called after the OpenGL context is established.
      # This is the place to register assets which depend on the GPU
      #
      # block - a callback to run code after an OpenGL window is established
      # 
      # Examples
      #
      #   Hokusai::Backend.run(App) do |config|
      #     config.after_load do
      #       Hokusai.fonts.register "default", Hokusai::Backend::Font.default
      #     end
      #   end
      # 
      # Returns nothing.
      def after_load(&block)
        self.after_load_cb = block
      end

      # Public: Sets hot reload entypoint (should probably be same as the app entrypoint)
      #         Note: for best results, also set `event_waiting = false`
      #
      # entrypoint - the file path to watch
      #
      # Returns nothing.
      def hot_reload=(entrypoint)
        @mtimes = {}
        topper = entrypoint
  
        on_reload do
          reload = false

          mtime = File::Stat.new(topper).mtime
          if !@mtimes[topper]
            @mtimes[topper] = mtime
          elsif @mtimes[topper] < mtime
            reload = true
            eval RubyResolver.new(topper).code, Backend.htop
            @mtimes[topper] = mtime
          end

          Reloader.new(topper).traverse do |file|
            mtime = File::Stat.new(file).mtime
            if !@mtimes[file]
              @mtimes[file] = mtime
            elsif @mtimes[file] < mtime
              reload = true

              eval RubyResolver.new(file).code, Backend.htop
              @mtimes[file] = mtime
            end
          end

          reload
        end
      end

      # Internal: Used by hot_reload= to set the reload logic
      def on_reload(&block)
        @on_reload_proc = block
      end
    end
  end
end


# Public: A block with a virtual node
#         useful for collecting events on a block without rendering anything
#         
# Examples
# 
#   template <<-EOF
#   [template]
#     empty { @click="do_something" }
#   EOF
#
class Hokusai::Blocks::Empty < Hokusai::Block
  template <<~EOF
    [template]
      virtual
  EOF

  def render(canvas)
    yield canvas
  end
end

module Hokusai
  module Blocks
    # Public: Renders all children vertically
    class Vblock < Hokusai::Block
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
  end
end

# Public: Renders all children horizontally
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
# Public: A simple label that changes node size according to text size
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
# Deprecated: A crappy button implmentation
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

# Public: Draws a circle
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

# Public: Checkbox
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

# Public: Starts a clipping region with everything
#         inside being clipped to the canvas dimensions
#         Last child should be [Hokusai::Blocks::ScissorEnd](/api/Hokusai/Blocks/ScissorEnd)
#         
# Examples
# 
#   template <<-EOF
#   [template]
#     scissor_begin
#       more
#         components
#       scissor_end
#   EOF
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
# Public: Stops clipping region
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

# Public: Clip descendants according to clipping region (slotted)
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
# Public: Represents a blinking cursor
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
# Public: Renders an image in Hokusai.images
class Hokusai::Blocks::Image < Hokusai::Block
  template <<~EOF
    [template]
      virtual
  EOF

  computed! :name
  computed :width, default: nil
  computed :height, default: nil
  computed :padding, default: Hokusai::Padding.new(0.0, 0.0, 0.0, 0.0), convert: Hokusai::Padding

  def render(canvas)
    if image = Hokusai.images.get(name)
      draw do
        image(image, canvas.x + padding.left, canvas.y + padding.top, (width&.to_f || canvas.width) - padding.right, (height&.to_f || canvas.height) - padding.bottom)
      end
    end

    yield canvas
  end
end
# Public: toggle for on/off scenarios
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
# Public: A scrollbar that emits the scroll position
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
    do_goto(goto, manual: false) unless goto.nil?
  end

  def percent_scrolled
    return 0 if scroll_top_height === 0

    scroll_top_height / (height - control_height)
  end

  def do_goto(value, manual: true)
    unless manual
      self.scroll_y = (value.to_f + control_height / 2.0)
    else
      self.scroll_y = value.to_f
    end

    emit("scroll", scroll_y, percent: percent_scrolled, manual: manual)
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
# Public: Measures it's children and emits the width and height
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

  def on_resize(_)
    compute_size
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
# Renders block inside a scrollable panel (slotted)
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

  # computed :padding, default: [0, 0, 0, 0], convert: Hokusai::Padding
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

  def local_percent_scrolled(y)
    return 0 if y === 0

    a = y / (panel_height - scroll_control_height)
  
    if a < 0.0
      0.0
    elsif a > 1.0
      1.0
    else
      a
    end
  end

  def wheel_handle(event)
    @wheel = true
    return if clipped_content_height <= panel_height

    new_scroll_y = scroll_y + event.scroll * 20

    if y = top
      # percent is 0.0
      if new_scroll_y < y
        self.scroll_y = y
        self.scroll_percent = 0.0
        self.scroll_goto_y = y
      # percent is 1.0
      elsif new_scroll_y - top >= panel_height
        if scroll_percent != 1.0
          self.scroll_y = panel_height
          self.scroll_goto_y = panel_height
          self.scroll_percent = 1.0
        end
      else
        # percent is in between
        self.scroll_goto_y = new_scroll_y
        self.scroll_y = new_scroll_y
        self.scroll_percent = local_percent_scrolled(new_scroll_y)
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

  def scroll_complete(y, percent:, manual:)
    if manual
      self.scroll_y = y
      self.scroll_percent = percent
    end

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

module Hokusai::Blocks
  # Public: A text rendering component
  class Text < Hokusai::Block
    template <<-EOF
    [template]
      virtual
    EOF

    computed! :content
    computed :static, default: false
    computed :font, default: nil
    computed :size, default: 20, convert: proc(&:to_i)
    computed :color, default: [22, 22, 22], convert: Hokusai::Color
    computed :padding, default: [0.0, 0.0, 0.0, 0.0], convert: Hokusai::Padding
    computed :selection_color, default: [183, 201, 229], convert: Hokusai::Color
    computed :selection_color_to, default: [183, 225, 229], convert: Hokusai::Color
    computed :animate_selection, default: true
    computed :copy_text, default: false
    
    inject :panel_offset
    inject :panel_height
    inject :panel_top
    inject :selection
  
    attr_accessor :counter, :copying

    def initialize(**args)
      @counter = 0
      @last_content = nil
      @copying = false
      @progress = 0
      
      super
    end

    def on_resize(canvas)
      @counter = 0
      @cache = nil
      @last_content = nil

      if selection
        selection.geom.cursor = nil
      end
    end

    def panel?
      !panel_offset.nil?
    end

    def user_font
      font ? Hokusai.fonts.get(font) : Hokusai.fonts.active
    end

    def top(canvas)
      canvas.y + (panel_offset || 0.0) + padding.top
    end

    def panel_height_or_canvas_height(canvas)
      panel_height || canvas.height
    end

    def cache(canvas)
      return @cache if counter >= 2 && static

      @cache = begin
        cache = Hokusai::Util::WrapCache.new
        y = top(canvas)

        stream = Hokusai::Util::WrapStream.new(canvas.width - padding.width, canvas.x, y) do |string, extra|
          if w = user_font.measure_char(string, size)
            [w, size]
          else
            [user_font.measure(string, size).first, size]
          end
        end

        stream.on_text do |wrapped|
          cache << wrapped
        end
        stream.wrap(content, nil)
        stream.flush

        if (stream.y - canvas.y).zero?
          height = size
        else
          height = (stream.y - canvas.y - offset + size).ceil
        end

        node.meta.set_prop(:height, height + padding.height)
        emit("height_updated", height + padding.height)
        @last_content = content

        cache
      end
    end

    def offset
      panel_offset || 0.0
    end

    def height(canvas)
      panel_height || canvas.height
    end

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
      if content.empty? || content.nil?
        yield canvas
      end

      token_cache = cache(canvas) 
      tokens = token_cache.tokens_for(Hokusai::Canvas.new(canvas.width, height(canvas), canvas.x, top(canvas)))

      # token selection
      if selection
        # set up for offset tracking
        selection.offset_y = (panel_offset || 0.0) if selection.geom.active?
        diff = selection.offset_y - (panel_offset || 0.0)
        selection.diff = diff

        if animate_selection
          shader_begin do |command|
            command.fragment_shader = fshader
            command.uniforms = {
              "from" => [selection_color.to_shader_value, HP_SHADER_UNIFORM_VEC4], 
              "to" => [selection_color_to.to_shader_value, HP_SHADER_UNIFORM_VEC4],
              "progress" => [@progress, HP_SHADER_UNIFORM_FLOAT]
            }
          end
        end

        copied = token_cache.selected_area_for_tokens(tokens, selection, copy: copying || copy_text, padding: padding) do |rect|
          y = rect.y + selection.diff
          rect(rect.x, y, rect.width, rect.height) do |command|
            command.color = selection_color
          end
        end

        emit("selected", copied) unless copied.nil?

        if copy_text
          Hokusai.copy(copied.copy)
          emit("copy", copied.copy)
        end

        if animate_selection
          shader_end
        end
      end

      tokens.each do |wrapped|
        # draw text
        text(wrapped.text, wrapped.x + padding.left, wrapped.y + padding.top - offset || 0.0) do |command|
          command.color = color
          command.size = size
          if font
            command.font = user_font
          end
        end
      end

      self.counter += 1 if counter < 2

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
end

module Hokusai::Util
  class GeometrySelection
    attr_accessor :start_x, :start_y, :stop_x, :stop_y,
                  :type, :cursor, :diff, :click_pos, :parent

    def initialize(parent)
      @parent = parent
      @type = :none         # state for the geometry selection (active/frozen/etc)
      @start_x = 0.0        # the x coordinate for the geometry
      @start_y = 0.0        # the y coordinate for the geometry 
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
  class Selection
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

# Public: slotted block which provides text selection information
#         to descendants
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
        selection.pos.cursor_index = nil
        selection.geom!

        selection.geom.clear
        selection.geom.start(event.pos.x, event.pos.y)
        selection.geom.set_click_pos(event.pos.x, event.pos.y)
      elsif selection.geom.frozen?
        selection.geom.click_pos = nil
        selection.geom.clear
      end
    end

    def update_selection(event)
      return unless selection.active?
      
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
end
module Hokusai::Blocks
  # Public: A text rendering component
  class Text < Hokusai::Block
    template <<-EOF
    [template]
      virtual
    EOF

    computed! :content
    computed :static, default: false
    computed :font, default: nil
    computed :size, default: 20, convert: proc(&:to_i)
    computed :color, default: [22, 22, 22], convert: Hokusai::Color
    computed :padding, default: [0.0, 0.0, 0.0, 0.0], convert: Hokusai::Padding
    computed :selection_color, default: [183, 201, 229], convert: Hokusai::Color
    computed :selection_color_to, default: [183, 225, 229], convert: Hokusai::Color
    computed :animate_selection, default: true
    computed :copy_text, default: false
    
    inject :panel_offset
    inject :panel_height
    inject :panel_top
    inject :selection
  
    attr_accessor :counter, :copying

    def initialize(**args)
      @counter = 0
      @last_content = nil
      @copying = false
      @progress = 0
      
      super
    end

    def on_resize(canvas)
      @counter = 0
      @cache = nil
      @last_content = nil

      if selection
        selection.geom.cursor = nil
      end
    end

    def panel?
      !panel_offset.nil?
    end

    def user_font
      font ? Hokusai.fonts.get(font) : Hokusai.fonts.active
    end

    def top(canvas)
      canvas.y + (panel_offset || 0.0) + padding.top
    end

    def panel_height_or_canvas_height(canvas)
      panel_height || canvas.height
    end

    def cache(canvas)
      return @cache if counter >= 2 && static

      @cache = begin
        cache = Hokusai::Util::WrapCache.new
        y = top(canvas)

        stream = Hokusai::Util::WrapStream.new(canvas.width - padding.width, canvas.x, y) do |string, extra|
          if w = user_font.measure_char(string, size)
            [w, size]
          else
            [user_font.measure(string, size).first, size]
          end
        end

        stream.on_text do |wrapped|
          cache << wrapped
        end
        stream.wrap(content, nil)
        stream.flush

        if (stream.y - canvas.y).zero?
          height = size
        else
          height = (stream.y - canvas.y - offset + size).ceil
        end

        node.meta.set_prop(:height, height + padding.height)
        emit("height_updated", height + padding.height)
        @last_content = content

        cache
      end
    end

    def offset
      panel_offset || 0.0
    end

    def height(canvas)
      panel_height || canvas.height
    end

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
      if content.empty? || content.nil?
        yield canvas
      end

      token_cache = cache(canvas) 
      tokens = token_cache.tokens_for(Hokusai::Canvas.new(canvas.width, height(canvas), canvas.x, top(canvas)))

      # token selection
      if selection
        # set up for offset tracking
        selection.offset_y = (panel_offset || 0.0) if selection.geom.active?
        diff = selection.offset_y - (panel_offset || 0.0)
        selection.diff = diff

        if animate_selection
          shader_begin do |command|
            command.fragment_shader = fshader
            command.uniforms = {
              "from" => [selection_color.to_shader_value, HP_SHADER_UNIFORM_VEC4], 
              "to" => [selection_color_to.to_shader_value, HP_SHADER_UNIFORM_VEC4],
              "progress" => [@progress, HP_SHADER_UNIFORM_FLOAT]
            }
          end
        end

        copied = token_cache.selected_area_for_tokens(tokens, selection, copy: copying || copy_text, padding: padding) do |rect|
          y = rect.y + selection.diff
          rect(rect.x, y, rect.width, rect.height) do |command|
            command.color = selection_color
          end
        end

        emit("selected", copied) unless copied.nil?

        if copy_text
          Hokusai.copy(copied.copy)
          emit("copy", copied.copy)
        end

        if animate_selection
          shader_end
        end
      end

      tokens.each do |wrapped|
        # draw text
        text(wrapped.text, wrapped.x + padding.left, wrapped.y + padding.top - offset || 0.0) do |command|
          command.color = color
          command.size = size
          if font
            command.font = user_font
          end
        end
      end

      self.counter += 1 if counter < 2

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
end


# Public: Input block, needs work
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
    @selection = Hokusai::Util::Selection.new
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

# Public: evaluates a Hokusai::Block from a string.  Dangerous.
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
# Public: A modal component
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

  computed :value, default: nil
  computed :x, default: nil
  computed :y, default: nil
  computed :flip, default: true
  
  def render(canvas)
    if tex = value
      draw do
        texture(tex, x || canvas.x, y || canvas.y) do |command|
          command.width = canvas.width
          command.height = canvas.height
          command.flip = flip
        end
      end
    end
  end
end

# Public: Starts a shader for this region that affects all descendants.
class Hokusai::Blocks::ShaderBegin < Hokusai::Block
  template <<~EOF
  [template]
    slot
  EOF

  computed :fragment_shader, default: nil
  computed :vertex_shader, default: nil
  computed :uniforms, default: {}
  computed :textures, default: {}

  def render(canvas)
    draw do
      shader_begin do |command|
        command.vertex_shader = vertex_shader
        command.fragment_shader = fragment_shader
        command.uniforms = uniforms
        command.textures = textures
      end
    end

    yield canvas
  end
end
# Public: Stops a shader defined by ShaderBegin
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

# Public: OpenGL Color picker
class Hokusai::Blocks::PickerCircle < Hokusai::Block
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
          texture { :value="texture" :flip="false" }
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
          texture { :value="texture" :flip="false" }
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
    shader_begin: Hokusai::Blocks::ShaderBegin, 
    shader_end: Hokusai::Blocks::ShaderEnd, 
    texture: Hokusai::Blocks::Texture,
    hblock: Hokusai::Blocks::Hblock,
    vblock: Hokusai::Blocks::Vblock,
    pickercircle: Hokusai::Blocks::PickerCircle
  )

  attr_accessor :position, :top, :left, :height, :width, :selecting, :selection,
                :brightness, :saturation, :pickerx, :pickery, :texture
  

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

    @texture ||= Hokusai::Texture.init(1, 1)

    yield canvas
  end
end
class Hokusai::Blocks::Translation < Hokusai::Block
  template <<~EOF
  [template]
    dynamic { 
      @size_updated="set_size" 
    }
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
    @start ||= Hokusai.monotonic

    time = Hokusai.monotonic - @start

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
# Public: A slider component with customizable min max and step
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

module Hokusai::Blocks
  # Public: A text rendering component
  class Text < Hokusai::Block
    template <<-EOF
    [template]
      virtual
    EOF

    computed! :content
    computed :static, default: false
    computed :font, default: nil
    computed :size, default: 20, convert: proc(&:to_i)
    computed :color, default: [22, 22, 22], convert: Hokusai::Color
    computed :padding, default: [0.0, 0.0, 0.0, 0.0], convert: Hokusai::Padding
    computed :selection_color, default: [183, 201, 229], convert: Hokusai::Color
    computed :selection_color_to, default: [183, 225, 229], convert: Hokusai::Color
    computed :animate_selection, default: true
    computed :copy_text, default: false
    
    inject :panel_offset
    inject :panel_height
    inject :panel_top
    inject :selection
  
    attr_accessor :counter, :copying

    def initialize(**args)
      @counter = 0
      @last_content = nil
      @copying = false
      @progress = 0
      
      super
    end

    def on_resize(canvas)
      @counter = 0
      @cache = nil
      @last_content = nil

      if selection
        selection.geom.cursor = nil
      end
    end

    def panel?
      !panel_offset.nil?
    end

    def user_font
      font ? Hokusai.fonts.get(font) : Hokusai.fonts.active
    end

    def top(canvas)
      canvas.y + (panel_offset || 0.0) + padding.top
    end

    def panel_height_or_canvas_height(canvas)
      panel_height || canvas.height
    end

    def cache(canvas)
      return @cache if counter >= 2 && static

      @cache = begin
        cache = Hokusai::Util::WrapCache.new
        y = top(canvas)

        stream = Hokusai::Util::WrapStream.new(canvas.width - padding.width, canvas.x, y) do |string, extra|
          if w = user_font.measure_char(string, size)
            [w, size]
          else
            [user_font.measure(string, size).first, size]
          end
        end

        stream.on_text do |wrapped|
          cache << wrapped
        end
        stream.wrap(content, nil)
        stream.flush

        if (stream.y - canvas.y).zero?
          height = size
        else
          height = (stream.y - canvas.y - offset + size).ceil
        end

        node.meta.set_prop(:height, height + padding.height)
        emit("height_updated", height + padding.height)
        @last_content = content

        cache
      end
    end

    def offset
      panel_offset || 0.0
    end

    def height(canvas)
      panel_height || canvas.height
    end

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
      if content.empty? || content.nil?
        yield canvas
      end

      token_cache = cache(canvas) 
      tokens = token_cache.tokens_for(Hokusai::Canvas.new(canvas.width, height(canvas), canvas.x, top(canvas)))

      # token selection
      if selection
        # set up for offset tracking
        selection.offset_y = (panel_offset || 0.0) if selection.geom.active?
        diff = selection.offset_y - (panel_offset || 0.0)
        selection.diff = diff

        if animate_selection
          shader_begin do |command|
            command.fragment_shader = fshader
            command.uniforms = {
              "from" => [selection_color.to_shader_value, HP_SHADER_UNIFORM_VEC4], 
              "to" => [selection_color_to.to_shader_value, HP_SHADER_UNIFORM_VEC4],
              "progress" => [@progress, HP_SHADER_UNIFORM_FLOAT]
            }
          end
        end

        copied = token_cache.selected_area_for_tokens(tokens, selection, copy: copying || copy_text, padding: padding) do |rect|
          y = rect.y + selection.diff
          rect(rect.x, y, rect.width, rect.height) do |command|
            command.color = selection_color
          end
        end

        emit("selected", copied) unless copied.nil?

        if copy_text
          Hokusai.copy(copied.copy)
          emit("copy", copied.copy)
        end

        if animate_selection
          shader_end
        end
      end

      tokens.each do |wrapped|
        # draw text
        text(wrapped.text, wrapped.x + padding.left, wrapped.y + padding.top - offset || 0.0) do |command|
          command.color = color
          command.size = size
          if font
            command.font = user_font
          end
        end
      end

      self.counter += 1 if counter < 2

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
end

# Public: Centers immediate descendants (slot)
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

    canvas.x = canvas.x + (canvas.width / 2.0) - a if horizontal || (!horizontal && !vertical)
    canvas.y = canvas.y + (canvas.height / 2.0) - b if vertical || (!horizontal && !vertical)

    yield canvas
  end
end
# Public: Spawns a directional tooltip
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
# Deprecated: Renders an icon
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
    up: "\u{E01E}",
    brush: "\u{E035}",
    times: "\u{E121}",
    scissor: "\u{E0DD}",
    info: "\u{E090}",
    zoomin: "\u{E14A}",
    zoomout: "\u{E14B}"
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
# Public: Dropdown item for Hokusai::Blocks::Dropdown
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

# Public: A dropdown menu.  takes the prop :options which is an array of strings
#         or an array of objects which respond to :value
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
    emit("change", active)
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

module Hokusai
  # Internal: Compile time patches for various sources
  module Patches
    # Internal: Patch for SDL Touch handling
    #           affects build using SDL/ARM64 architecture
    def self.sdl_patch
      <<~BAD
diff --git a/src/platforms/rcore_desktop_sdl.c b/src/platforms/rcore_desktop_sdl.c
index a201f2c..3d0e4a1 100644
--- a/src/platforms/rcore_desktop_sdl.c
+++ b/src/platforms/rcore_desktop_sdl.c
@@ -1342,10 +1342,17 @@ void PollInputEvents(void)
     }
 
     // Register previous touch states
-    for (int i = 0; i < MAX_TOUCH_POINTS; i++) CORE.Input.Touch.previousTouchState[i] = CORE.Input.Touch.currentTouchState[i];
+    for (int i = 0; i < MAX_TOUCH_POINTS; i++)
+    {
+      CORE.Input.Touch.previousTouchState[i] = CORE.Input.Touch.currentTouchState[i];
+      // todo clear touch position?
+      // CORE.Input.Touch.position[i].x = -1;
+      // CORE.Input.Touch.position[i].y = -1;
+      // CORE.Input.Touch.pointId[i] = -1;
+    }
 
-    // Map touch position to mouse position for convenience
-    CORE.Input.Touch.position[0] = CORE.Input.Mouse.currentPosition;
+    // // Map touch position to mouse position for convenience
+    // CORE.Input.Touch.position[0] = CORE.Input.Mouse.currentPosition;
 
     int touchAction = -1;       // 0-TOUCH_ACTION_UP, 1-TOUCH_ACTION_DOWN, 2-TOUCH_ACTION_MOVE
     bool realTouch = false;     // Flag to differentiate real touch gestures from mouse ones
@@ -1583,13 +1590,19 @@ void PollInputEvents(void)
             } break;
             case SDL_FINGERUP:
             {
+                int count = CORE.Input.Touch.pointCount;
                 UpdateTouchPointsSDL(event.tfinger);
+                CORE.Input.Touch.pointCount = count;
+
                 touchAction = 0;
                 realTouch = true;
             } break;
             case SDL_FINGERMOTION:
             {
+                int count = CORE.Input.Touch.pointCount;
                 UpdateTouchPointsSDL(event.tfinger);
+                CORE.Input.Touch.pointCount = count;
+
                 touchAction = 2;
                 realTouch = true;
             } break;
@@ -1738,28 +1751,42 @@ void PollInputEvents(void)
         {
             // Process mouse events as touches to be able to use mouse-gestures
             GestureEvent gestureEvent = { 0 };
-
             // Register touch actions
             gestureEvent.touchAction = touchAction;
 
-            // Assign a pointer ID
-            gestureEvent.pointId[0] = 0;
-
-            // Register touch points count
-            gestureEvent.pointCount = 1;
-
-            // Register touch points position, only one point registered
-            if (touchAction == 2 || realTouch) gestureEvent.position[0] = CORE.Input.Touch.position[0];
-            else gestureEvent.position[0] = GetMousePosition();
-
-            // Normalize gestureEvent.position[0] for CORE.Window.screen.width and CORE.Window.screen.height
-            gestureEvent.position[0].x /= (float)GetScreenWidth();
-            gestureEvent.position[0].y /= (float)GetScreenHeight();
+            if (realTouch)
+            {
+              // Register touch points count
+              gestureEvent.pointCount = CORE.Input.Touch.pointCount;
+
+              // we want to track every touch.
+              for (int i = 0; i < CORE.Input.Touch.pointCount; i++)
+              {
+                gestureEvent.pointId[i] = i;
+                gestureEvent.position[i].x = CORE.Input.Touch.position[i].x / (float)GetScreenWidth();
+                gestureEvent.position[i].y = CORE.Input.Touch.position[i].y / (float)GetScreenWidth();
+              }
+            }
+            else
+            {
+              // Register touch points count
+              gestureEvent.pointCount = 1;
+              // Assign a pointer ID
+              gestureEvent.pointId[0] = 0;
+              // Register touch points position, only one point registered
+              if (touchAction == 2 || realTouch) gestureEvent.position[0] = CORE.Input.Touch.position[0];
+              else gestureEvent.position[0] = GetMousePosition();
+
+              // Normalize gestureEvent.position[0] for CORE.Window.screen.width and CORE.Window.screen.height
+              gestureEvent.position[0].x /= (float)GetScreenWidth();
+              gestureEvent.position[0].y /= (float)GetScreenHeight();
+            }
 
             // Gesture data is sent to gestures-system for processing
             ProcessGestureEvent(gestureEvent);
 
             touchAction = -1;
+            realTouch = false;
         }
 #endif
     }

BAD
    end

    # Internal: Patch for raylib to compile against different sources
    #           Thanks to the [Taylor](https://taylormadetech.dev/) project for this
    def self.raylib_patch
      <<~BAD

# Raylib patch
COPY <<EOT /app/vendor/raylib/tweaks.patch
diff --git a/src/Makefile b/src/Makefile
index 7dde52fb..666fe315 100644
--- a/src/Makefile
+++ b/src/Makefile
@@ -270,10 +270,22 @@ CC = gcc
 AR = ar
 
 ifeq ($(TARGET_PLATFORM),PLATFORM_DESKTOP_GLFW)
-    ifeq ($(PLATFORM_OS),OSX)
-        # OSX default compiler
-        CC = clang
-        GLFW_OSX = -x objective-c
+    ifeq ($(CROSS),MINGW)
+        CC = x86_64-w64-mingw32-gcc
+        AR = x86_64-w64-mingw32-ar
+        CFLAGS += -static-libgcc -lopengl32 -lgdi32 -lwinmm
+    endif
+    ifeq ($(CROSS),OSX_INTEL)
+      CC = x86_64-apple-darwin20.4-clang
+      AR = x86_64-apple-darwin20.4-ar
+      CFLAGS = -compatibility_version $(RAYLIB_API_VERSION) -current_version $(RAYLIB_VERSION) -framework OpenGL -framework Cocoa -framework IOKit -framework CoreAudio -framework CoreVideo
+      GLFW_OSX = -x objective-c
+    endif
+    ifeq ($(CROSS),OSX_APPLE)
+      CC = arm64-apple-darwin20.4-clang
+      AR = arm64-apple-darwin20.4-ar
+      CFLAGS = -compatibility_version $(RAYLIB_API_VERSION) -current_version $(RAYLIB_VERSION) -framework OpenGL -framework Cocoa -framework IOKit -framework CoreAudio -framework CoreVideo
+      GLFW_OSX = -x objective-c
     endif
     ifeq ($(PLATFORM_OS),BSD)
         # FreeBSD, OpenBSD, NetBSD, DragonFly default compiler
diff --git a/src/config.h b/src/config.h
index e3749c56..b271a525 100644
--- a/src/config.h
+++ b/src/config.h
@@ -165,14 +165,14 @@
 //------------------------------------------------------------------------------------
 // Selecte desired fileformats to be supported for image data loading
 #define SUPPORT_FILEFORMAT_PNG      1
-//#define SUPPORT_FILEFORMAT_BMP      1
+#define SUPPORT_FILEFORMAT_BMP      1
 //#define SUPPORT_FILEFORMAT_TGA      1
-//#define SUPPORT_FILEFORMAT_JPG      1
+#define SUPPORT_FILEFORMAT_JPG      1
 #define SUPPORT_FILEFORMAT_GIF      1
 #define SUPPORT_FILEFORMAT_QOI      1
 //#define SUPPORT_FILEFORMAT_PSD      1
 #define SUPPORT_FILEFORMAT_DDS      1
-//#define SUPPORT_FILEFORMAT_HDR      1
+#define SUPPORT_FILEFORMAT_HDR      1
 //#define SUPPORT_FILEFORMAT_PIC          1
 //#define SUPPORT_FILEFORMAT_KTX      1
 //#define SUPPORT_FILEFORMAT_ASTC     1
diff --git a/src/raylib.h b/src/raylib.h
index a26b8ce6..798d7bd0 100644
--- a/src/raylib.h
+++ b/src/raylib.h
@@ -1360,7 +1360,7 @@ RLAPI void ImageAlphaPremultiply(Image *image);
 RLAPI void ImageBlurGaussian(Image *image, int blurSize);                                                // Apply Gaussian blur using a box blur approximation
 RLAPI void ImageKernelConvolution(Image *image, const float *kernel, int kernelSize);                    // Apply custom square convolution kernel to image
 RLAPI void ImageResize(Image *image, int newWidth, int newHeight);                                       // Resize image (Bicubic scaling algorithm)
-RLAPI void ImageResizeNN(Image *image, int newWidth,int newHeight);                                      // Resize image (Nearest-Neighbor scaling algorithm)
+RLAPI void ImageResizeNN(Image *image, int newWidth, int newHeight);                                     // Resize image (Nearest-Neighbor scaling algorithm)
 RLAPI void ImageResizeCanvas(Image *image, int newWidth, int newHeight, int offsetX, int offsetY, Color fill); // Resize canvas and fill with color
 RLAPI void ImageMipmaps(Image *image);                                                                   // Compute all mipmap levels for a provided image
 RLAPI void ImageDither(Image *image, int rBpp, int gBpp, int bBpp, int aBpp);                            // Dither image data to 16bpp or lower (Floyd-Steinberg dithering)
EOT

BAD
    end

    # Internal: A bunch of patches for TLSUV
    #           TODO: Remove dependency
    def self.tlsuv_patch
      <<-BAD
diff --git a/CMakeLists.txt b/CMakeLists.txt
index b7e81c5..acb182f 100644
--- a/CMakeLists.txt
+++ b/CMakeLists.txt
@@ -100,6 +100,8 @@ if (TARGET libuv::uv)
     message(NOTICE "upstream project set libuv target")
     set(TLSUV_LIBUV_LIB libuv::uv)
     set(libuv_FOUND TRUE)
+elseif(TLSUV_LIBUV_LIB)
+  message(NOTICE, "Setting from cli")
 else ()
     find_package(libuv CONFIG QUIET)
     # newer libuv versions (via VCPKG) have proper namespacing
@@ -114,11 +116,6 @@ else ()
     endif()
 endif ()
 
-if (NOT libuv_FOUND)
-    pkg_check_modules(libuv REQUIRED IMPORTED_TARGET libuv)
-    set(TLSUV_LIBUV_LIB PkgConfig::libuv)
-endif()
-
 add_library(tlsuv STATIC
         ${tlsuv_sources}
         )
@@ -134,6 +131,10 @@ target_include_directories(tlsuv
         $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/generated>
         PRIVATE
         ${CMAKE_CURRENT_SOURCE_DIR}/src
+        ${CMAKE_CURRENT_SOURCE_DIR}/${TLSUV_LIBUV_INCLUDE}
+        ${CMAKE_CURRENT_SOURCE_DIR}/${LLHTTP_INCLUDE}
+        ${CMAKE_CURRENT_SOURCE_DIR}/${MBEDTLS_INCLUDE}
+        ${CMAKE_CURRENT_SOURCE_DIR}/${ZLIB_INCLUDE}
 )
 
 target_compile_definitions(tlsuv PRIVATE
@@ -179,18 +180,22 @@ if (TLSUV_HTTP)
     add_subdirectory(deps)
     target_link_libraries(tlsuv PUBLIC uv_link)
 
-    find_package(ZLIB 1 REQUIRED)
-    target_link_libraries(tlsuv PRIVATE ZLIB::ZLIB)
+    message(NOTICE "${CMAKE_CURRENT_SOURCE_DIR}/../../${ZLIB_LIB}")
+    target_link_libraries(tlsuv PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/${ZLIB_LIB}")
 
-    find_package(llhttp CONFIG REQUIRED)
-    message(NOTICE "llhttp = ${llhttp_CONFIG}")
-    if (TARGET llhttp::llhttp_static)
-        target_link_libraries(tlsuv PUBLIC llhttp::llhttp_static)
-    elseif (TARGET llhttp::llhttp_shared)
-        target_link_libraries(tlsuv PUBLIC llhttp::llhttp_shared)
+    if (LLHTTP_LIB)
+      target_link_libraries(tlsuv PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/${LLHTTP_LIB}")
     else ()
-        target_link_libraries(tlsuv PUBLIC llhttp::llhttp)
-    endif ()
+
+      message(NOTICE "llhttp = ${llhttp_CONFIG}")
+      if (TARGET llhttp::llhttp_static)
+          target_link_libraries(tlsuv PUBLIC llhttp::llhttp_static)
+      elseif (TARGET llhttp::llhttp_shared)
+          target_link_libraries(tlsuv PUBLIC llhttp::llhttp_shared)
+      else ()
+          target_link_libraries(tlsuv PUBLIC llhttp::llhttp)
+      endif ()
+    endif (LLHTTP_LIB)
 
 endif (TLSUV_HTTP)
 
diff --git a/cmake/FindMbedTLS.cmake b/cmake/FindMbedTLS.cmake
index 7dd4e32..132ef2a 100644
--- a/cmake/FindMbedTLS.cmake
+++ b/cmake/FindMbedTLS.cmake
@@ -1,17 +1,23 @@
-find_path(MBEDTLS_INCLUDE_DIRS mbedtls/ssl.h)
+ find_path(${CMAKE_CURRENT_SOURCE_DIR}/MBEDTLS_INCLUDE_DIRS mbedtls/ssl.h)
 
 # mbedtls-3.0 changed headers files, and we need to ifdef'out a few things
-find_path(MBEDTLS_VERSION_GREATER_THAN_3 mbedtls/build_info.h)
+find_path(MBEDTLS_VERSION_GREATER_THAN_3 ${CMAKE_CURRENT_SOURCE_DIR}/../MBEDTLS_INCLUDE_DIRS mbedtls/build_info.h)
 message("MBEDTLS_VERSION_GREATER_THAN_3 = ${MBEDTLS_VERSION_GREATER_THAN_3}")
+if (true)
+      message(NOTICE "Looking:${CMAKE_CURRENT_SOURCE_DIR}/../../${MBEDTLS_LIBRARY}")
+      message(NOTICE "Looking:${CMAKE_CURRENT_SOURCE_DIR}/../../${MBEDTLS_LIBRARY}")
+      message(NOTICE "Looking:${CMAKE_CURRENT_SOURCE_DIR}/../../${MBEDTLS_LIBRARY}")
 
-find_library(MBEDTLS_LIBRARY mbedtls)
-find_library(MBEDX509_LIBRARY mbedx509)
-find_library(MBEDCRYPTO_LIBRARY mbedcrypto)
+endif()
+
+find_library("${CMAKE_CURRENT_SOURCE_DIR}/../../${MBEDTLS_LIBRARY}" mbedtls)
+find_library("${CMAKE_CURRENT_SOURCE_DIR}/../../${MBEDX509_LIBRARY}" mbedx509)
+find_library("${CMAKE_CURRENT_SOURCE_DIR}/../../${MBEDCRYPTO_LIBRARY}" mbedcrypto)
 
 set(MBEDTLS_LIBRARIES "${MBEDTLS_LIBRARY}" "${MBEDX509_LIBRARY}" "${MBEDCRYPTO_LIBRARY}")
 
-include(FindPackageHandleStandardArgs)
-find_package_handle_standard_args(MbedTLS DEFAULT_MSG
-    MBEDTLS_INCLUDE_DIRS MBEDTLS_LIBRARY MBEDX509_LIBRARY MBEDCRYPTO_LIBRARY)
+# include(FindPackageHandleStandardArgs)
+# find_package_handle_standard_args(MbedTLS DEFAULT_MSG
+#     MBEDTLS_INCLUDE_DIRS MBEDTLS_LIBRARY MBEDX509_LIBRARY MBEDCRYPTO_LIBRARY)
 
-mark_as_advanced(MBEDTLS_INCLUDE_DIRS MBEDTLS_LIBRARY MBEDX509_LIBRARY MBEDCRYPTO_LIBRARY)
+mark_as_advanced(MBEDTLS_INCLUDE_DIRS MBEDTLS_LIBRARY MBEDX509_LIBRARY MBEDCRYPTO_LIBRARY)
\\ No newline at end of file
diff --git a/deps/CMakeLists.txt b/deps/CMakeLists.txt
index 2279051..3d74473 100644
--- a/deps/CMakeLists.txt
+++ b/deps/CMakeLists.txt
@@ -1,2 +1,17 @@
+set(uvl_src ${CMAKE_CURRENT_SOURCE_DIR}/uv_link_t)
+add_library(uv_link OBJECT
+        ${uvl_src}/src/uv_link_t.c
+        ${uvl_src}/src/uv_link_source_t.c
+        ${uvl_src}/src/uv_link_observer_t.c
+        ${uvl_src}/src/defaults.c)
 
-include(uv_link.cmake)
\\ No newline at end of file
+target_include_directories(uv_link
+        PUBLIC ${uvl_src}/include
+        PRIVATE ${uvl_src}
+        PUBLIC
+        ${CMAKE_CURRENT_SOURCE_DIR}/../${TLSUV_LIBUV_INCLUDE}
+        ${CMAKE_CURRENT_SOURCE_DIR}/../${LLHTTP_INCLUDE}
+)
+
+set_target_properties(uv_link PROPERTIES POSITION_INDEPENDENT_CODE ON)
+target_link_libraries(uv_link ${TLSUV_LIBUV_LIB})
diff --git a/src/mbedtls/CMakeLists.txt b/src/mbedtls/CMakeLists.txt
index 323f500..85aed28 100644
--- a/src/mbedtls/CMakeLists.txt
+++ b/src/mbedtls/CMakeLists.txt
@@ -1,14 +1,25 @@
 find_package(MbedTLS REQUIRED)
 
 add_library(mbedtls-impl OBJECT
-        engine.c
-        keys.c
-        keys.h
+      engine.c
+      keys.c
+      keys.h
+)
+
+if (true)
+      message(NOTICE "Found:${CMAKE_CURRENT_SOURCE_DIR}/../../${MBEDTLS_INCLUDE_DIRS}")
+endif()
+include_directories(mbedtls-impl
+      PRIVATE ${PROJECT_SOURCE_DIR}/include
+      PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/..
+      PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/../../${MBEDTLS_INCLUDE_DIRS}
 )
 
 target_include_directories(mbedtls-impl
-        PRIVATE ${PROJECT_SOURCE_DIR}/include
-        PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/..
-        PRIVATE $<BUILD_INTERFACE:${MBEDTLS_INCLUDE_DIRS}>
+  PUBLIC
+  "${CMAKE_CURRENT_SOURCE_DIR}/../../${TLSUV_LIBUV_INCLUDE}"
+  "${CMAKE_CURRENT_SOURCE_DIR}/../../${LLHTTP_INCLUDE}"
+  "${CMAKE_CURRENT_SOURCE_DIR}/../../${MBEDTLS_INCLUDE}"
 )
-target_link_libraries(mbedtls-impl PRIVATE ${MBEDTLS_LIBRARIES})
+
+target_link_libraries(mbedtls-impl PRIVATE MBEDTLS_LIBRARIES)
\\ No newline at end of file
diff --git a/src/mbedtls/engine.c b/src/mbedtls/engine.c
index 3d9e2f9..6dc6dad 100644
--- a/src/mbedtls/engine.c
+++ b/src/mbedtls/engine.c
@@ -91,7 +91,7 @@ struct mbedtls_engine {
     mbedtls_ssl_session *session;
 
     io_ctx io;
-    uv_os_fd_t io_fd;
+    uv_os_sock_t io_fd;
     io_read read_f;
     io_write write_f;
 
@@ -111,7 +111,7 @@ static int mbedtls_set_own_cert(tls_context *ctx, tlsuv_private_key_t key, tlsuv
 tlsuv_engine_t new_mbedtls_engine(tls_context *ctx, const char *host);
 
 static void mbedtls_set_io(tlsuv_engine_t, io_ctx , io_read , io_write );
-static void mbedtls_set_fd(tlsuv_engine_t, uv_os_fd_t );
+static void mbedtls_set_fd(tlsuv_engine_t, uv_os_sock_t );
 
 static tls_handshake_state mbedtls_hs_state(tlsuv_engine_t engine);
 static tls_handshake_state
@@ -720,7 +720,7 @@ static void mbedtls_set_io(tlsuv_engine_t e, io_ctx io, io_read read_f, io_write
     mbedtls_ssl_set_bio(eng->ssl, eng, engine_io_write, engine_io_read, NULL);
 }
 
-static void mbedtls_set_fd(tlsuv_engine_t e, uv_os_fd_t fd) {
+static void mbedtls_set_fd(tlsuv_engine_t e, uv_os_sock_t fd) {
     struct mbedtls_engine *eng = (struct mbedtls_engine *) e;
     assert(eng->io == NULL);
     eng->io_fd = fd;
diff --git a/src/apple/keychain.c b/src/apple/keychain.c
index 24fe128..42dd256 100644
--- a/src/apple/keychain.c
+++ b/src/apple/keychain.c
@@ -1,6 +1,6 @@
 
-#include <security/SecKey.h>
-#include <security/Security.h>
+#include <Security/SecKey.h>
+#include <Security/Security.h>
 
 #include "../keychain.h"
 #include "um_debug.h"
BAD
    end
  end
end

# Depends on docker for cross-compilation
# All cross-compilation is done on linux
#
# Template for cross platform docker builds
# os : <osx|windows|linux>
# target: <app.rb>
module Hokusai
  # Internal: Docker templates that get written to disk by binary
  #           during cross platform publishing
  def self.docker_template
    <<~HELL
FROM skinnyjames/mruby-cross-<%= os %> as cross
    
RUN apt update -y && apt-get install -y wget <%= deps %>

WORKDIR /temp
RUN wget https://github.com/skinnyjames/mruby-bin-barista/releases/download/0.3.1/barista-linux-x86.tar.gz && \
    tar -xvf barista-linux-x86.tar.gz && \
    chmod 755 barista-linux-x86/barista && \
    cp barista-linux-x86/barista /usr/bin/.

WORKDIR /app

RUN git clone --branch 5.5 --depth 1 https://github.com/raysan5/raylib.git vendor/raylib
RUN git clone --depth 1 https://github.com/tree-sitter/tree-sitter.git vendor/tree-sitter
RUN git clone --branch stable --depth 1 https://github.com/mruby/mruby.git vendor/mruby
RUN git clone --branch main --depth 1 https://github.com/skinnyjames/hokusai-pocket.git vendor/hp
RUN git clone https://github.com/mlabbe/nativefiledialog.git vendor/nfd
RUN git clone https://github.com/libuv/libuv vendor/libuv

# fetch http deps
RUN wget -O vendor/llhttp.tar.gz https://github.com/nodejs/llhttp/archive/refs/tags/release/v9.3.1.tar.gz && \
    cd vendor && tar -xvf llhttp.tar.gz && mv llhttp-release-v9.3.1 llhttp

RUN wget -O vendor/mbedtls.tar.bz2 https://github.com/Mbed-TLS/mbedtls/releases/download/mbedtls-3.6.6/mbedtls-3.6.6.tar.bz2 && \
    cd vendor && tar -xvf mbedtls.tar.bz2 && mv mbedtls-3.6.6 mbedtls

RUN git clone https://github.com/madler/zlib.git vendor/zlib

RUN wget -O vendor/tlsuv.tar.gz https://github.com/openziti/tlsuv/archive/refs/tags/v0.41.1.tar.gz && \
    cd vendor && tar -xvf tlsuv.tar.gz && mv tlsuv-0.41.1 tlsuv
    

# build mruby
WORKDIR /app/vendor/mruby

<% if os == "osx" %>
COPY <<EOT build_config.rb
MRuby::CrossBuild.new("platform") do |conf|
  toolchain :clang

  [conf.cc, conf.linker].each do |cc|
    cc.command = "x86_64-apple-darwin20.4-clang"
    cc.flags += %w[-O2 -mmacosx-version-min=10.11 -stdlib=libc++]
  end
  conf.cc.flags += %w[-DMRB_ARY_LENGTH_MAX=0 -DMRB_STR_LENGTH_MAX=0]

  conf.cxx.command = "x86_64-apple-darwin20.4-clang++"
  conf.archiver.command = "x86_64-apple-darwin20.4-ar"

  conf.build_target = "x86_64-pc-linux-gnu"
  conf.host_target = "x86_64-apple-darwin20.4"
  
  conf.gembox "stdlib"
  conf.gembox "stdlib-ext"
  conf.gembox "stdlib-io"
  conf.gembox "math"
  conf.gembox "metaprog"
  conf.gem :github => 'iij/mruby-env'
  conf.gem github: "skinnyjames-mruby/mruby-regexp-pcre"
  conf.gem github: "skinnyjames-mruby/mruby-dir-glob", canonical: true
  <%= gem_config %>

  # Generate mrbc command
  conf.gem :core => "mruby-bin-mrbc"
end
EOT
<% elsif os == "windows" %>
COPY <<EOT build_config.rb
MRuby::CrossBuild.new("platform") do |conf|
  conf.toolchain :gcc

  conf.cc.flags += %w[-DMRB_ARY_LENGTH_MAX=0 -DMRB_STR_LENGTH_MAX=0]

  conf.host_target = "x86_64-w64-mingw32"  # required for `for_windows?` used by `mruby-socket` gem

  conf.cc.command = "\#{conf.host_target}-gcc-posix"
  conf.cc.flags += %w[-O2]
  conf.linker.command = conf.cc.command
  conf.archiver.command = "\#{conf.host_target}-gcc-ar"
  conf.exts.executable = ".exe"
  conf.gem :github => 'iij/mruby-env'
  conf.gem github: "skinnyjames-mruby/mruby-regexp-pcre"
  conf.gem github: "skinnyjames-mruby/mruby-dir-glob", canonical: true
  <%= gem_config %>

  conf.gembox "default"
end
EOT
<% else %>
COPY <<EOT build_config.rb
MRuby::CrossBuild.new("platform") do |conf|
  if ENV['VisualStudioVersion'] || ENV['VSINSTALLDIR']
    toolchain :visualcpp
  else
    toolchain :gcc
  end
  conf.gem :github => 'iij/mruby-env'
  conf.gem github: "skinnyjames-mruby/mruby-regexp-pcre"
  conf.gem github: "skinnyjames-mruby/mruby-dir-glob", canonical: true
  <%= gem_config %>

  conf.gembox "default"
end
EOT
<% end %>

RUN unset LD && unset CC && unset CXX && unset AR && rake MRUBY_CONFIG=build_config.rb

# Raylib patch
COPY <<EOT /app/vendor/raylib/tweaks.patch
diff --git a/src/Makefile b/src/Makefile
index 7dde52fb..666fe315 100644
--- a/src/Makefile
+++ b/src/Makefile
@@ -270,10 +270,22 @@ CC = gcc
 AR = ar
 
 ifeq ($(TARGET_PLATFORM),PLATFORM_DESKTOP_GLFW)
-    ifeq ($(PLATFORM_OS),OSX)
-        # OSX default compiler
-        CC = clang
-        GLFW_OSX = -x objective-c
+    ifeq ($(CROSS),MINGW)
+        CC = x86_64-w64-mingw32-gcc
+        AR = x86_64-w64-mingw32-ar
+        CFLAGS += -static-libgcc -lopengl32 -lgdi32 -lwinmm
+    endif
+    ifeq ($(CROSS),OSX_INTEL)
+      CC = x86_64-apple-darwin20.4-clang
+      AR = x86_64-apple-darwin20.4-ar
+      CFLAGS = -compatibility_version $(RAYLIB_API_VERSION) -current_version $(RAYLIB_VERSION) -framework OpenGL -framework Cocoa -framework IOKit -framework CoreAudio -framework CoreVideo
+      GLFW_OSX = -x objective-c
+    endif
+    ifeq ($(CROSS),OSX_APPLE)
+      CC = arm64-apple-darwin20.4-clang
+      AR = arm64-apple-darwin20.4-ar
+      CFLAGS = -compatibility_version $(RAYLIB_API_VERSION) -current_version $(RAYLIB_VERSION) -framework OpenGL -framework Cocoa -framework IOKit -framework CoreAudio -framework CoreVideo
+      GLFW_OSX = -x objective-c
     endif
     ifeq ($(PLATFORM_OS),BSD)
         # FreeBSD, OpenBSD, NetBSD, DragonFly default compiler
diff --git a/src/config.h b/src/config.h
index e3749c56..b271a525 100644
--- a/src/config.h
+++ b/src/config.h
@@ -165,14 +165,14 @@
 //------------------------------------------------------------------------------------
 // Selecte desired fileformats to be supported for image data loading
 #define SUPPORT_FILEFORMAT_PNG      1
-//#define SUPPORT_FILEFORMAT_BMP      1
+#define SUPPORT_FILEFORMAT_BMP      1
 //#define SUPPORT_FILEFORMAT_TGA      1
-//#define SUPPORT_FILEFORMAT_JPG      1
+#define SUPPORT_FILEFORMAT_JPG      1
 #define SUPPORT_FILEFORMAT_GIF      1
 #define SUPPORT_FILEFORMAT_QOI      1
 //#define SUPPORT_FILEFORMAT_PSD      1
 #define SUPPORT_FILEFORMAT_DDS      1
-//#define SUPPORT_FILEFORMAT_HDR      1
+#define SUPPORT_FILEFORMAT_HDR      1
 //#define SUPPORT_FILEFORMAT_PIC          1
 //#define SUPPORT_FILEFORMAT_KTX      1
 //#define SUPPORT_FILEFORMAT_ASTC     1
diff --git a/src/raylib.h b/src/raylib.h
index a26b8ce6..798d7bd0 100644
--- a/src/raylib.h
+++ b/src/raylib.h
@@ -1360,7 +1360,7 @@ RLAPI void ImageAlphaPremultiply(Image *image);
 RLAPI void ImageBlurGaussian(Image *image, int blurSize);                                                // Apply Gaussian blur using a box blur approximation
 RLAPI void ImageKernelConvolution(Image *image, const float *kernel, int kernelSize);                    // Apply custom square convolution kernel to image
 RLAPI void ImageResize(Image *image, int newWidth, int newHeight);                                       // Resize image (Bicubic scaling algorithm)
-RLAPI void ImageResizeNN(Image *image, int newWidth,int newHeight);                                      // Resize image (Nearest-Neighbor scaling algorithm)
+RLAPI void ImageResizeNN(Image *image, int newWidth, int newHeight);                                     // Resize image (Nearest-Neighbor scaling algorithm)
 RLAPI void ImageResizeCanvas(Image *image, int newWidth, int newHeight, int offsetX, int offsetY, Color fill); // Resize canvas and fill with color
 RLAPI void ImageMipmaps(Image *image);                                                                   // Compute all mipmap levels for a provided image
 RLAPI void ImageDither(Image *image, int rBpp, int gBpp, int bBpp, int aBpp);                            // Dither image data to 16bpp or lower (Floyd-Steinberg dithering)
EOT

RUN apt update -y && apt install -y gpg

# Source - https://stackoverflow.com/a/56690743
# Posted by Liu Hao Cheng, modified by community. See post 'Timeline' for change history
# Retrieved 2026-05-18, License - CC BY-SA 4.0
RUN wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | tee /usr/share/keyrings/kitware-archive-keyring.gpg >/dev/null
RUN echo 'deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ jammy main' | tee /etc/apt/sources.list.d/kitware.list >/dev/null
RUN apt-get update -y && apt-get install -y cmake

<% if os == "windows" %>
# Create the mingw64-cmake wrapper
RUN echo '#!/bin/sh\\nexec cmake -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_C_COMPILER=x86_64-w64-mingw32-gcc -DCMAKE_CXX_COMPILER=x86_64-w64-mingw32-g++ -DCMAKE_FIND_ROOT_PATH=/usr/x86_64-w64-mingw32 "$@"' > /usr/local/bin/cmake-wrap \
    && chmod +x /usr/local/bin/cmake-wrap
ENV CC=x86_64-w64-mingw32-gcc-posix
ENV AR=x86_64-w64-mingw32-gcc-ar
ENV ZLIBA="libzs.a"
<% elsif os == "osx" %>
RUN echo '#!/bin/sh\\nexec cmake -DCMAKE_SYSTEM_NAME=Darwin -DCMAKE_C_COMPILER=x86_64-apple-darwin20.4-clang -DCMAKE_CXX_COMPILER=x86_64-apple-darwin20.4-clang++ -DCMAKE_FIND_ROOT_PATH=/opt/osxcross/target "$@"' > /usr/local/bin/cmake-wrap \
    && chmod +x /usr/local/bin/cmake-wrap
ENV OSXCROSS_ROOT=/opt/osxcross/target
ENV OSXCROSS_HOST=x86_64-linux-gnu
ENV OSXCROSS_TARGET_DIR=/opt/osxcross/target
ENV OSXCROSS_TARGET=x86_64-apple-darwin20.4
ENV OSXCROSS_SDK_DIR=$OSXCROSS_TARGET_DIR/SDK
ENV OSXCROSS_SDK="MacOSX11.3.sdk"
ENV CC=x86_64-apple-darwin20.4-clang
ENV AR=x86_64-apple-darwin20.4-ar
ENV ZLIBA="libz.a"
<% else %>
RUN echo '#!/bin/sh\\nexec cmake "$@"' > /usr/local/bin/cmake-wrap \
    && chmod +x /usr/local/bin/cmake-wrap
ENV CC=gcc
ENV AR=ar
ENV ZLIBA="libz.a"
<% end %>

WORKDIR /app/vendor/raylib
RUN git apply tweaks.patch

WORKDIR /app/vendor/raylib/src

# build raylib
<% if os == "windows" %>
RUN make -j 5 PLATFORM=PLATFORM_DESKTOP PLATFORM_OS=WINDOWS CROSS=MINGW
<% elsif os == "osx" %>
RUN make -j 5 PLATFORM=PLATFORM_DESKTOP PLATFORM_OS=OSX CROSS=OSX_INTEL
<% else %>
RUN make -j 5 PLATFORM=PLATFORM_DESKTOP
<% end %>

# build tree-sitter
RUN mkdir -p /app/vendor/tree-sitter/build
WORKDIR /app/vendor/tree-sitter
RUN make -j 5 all install PREFIX=build CC=$CC AR=$AR

# build nfd
WORKDIR /app/vendor/nfd
<% if os == "windows" %>
# RUN apt install -y  g++-mingw-w64-ucrt64 gcc-mingw-w64-ucrt64
ENV CPATH=/usr/x86_64-w64-mingw32/include:$CPATH
ENV CC=x86_64-w64-mingw32-gcc
ENV CXX=x86_64-w64-mingw32-g++

RUN cd build/gmake_windows && make clean
RUN cd build/gmake_windows && make config=release_x64 verbose=1
<% elsif os == "osx" %>
RUN cd build/gmake_macosx && make config=release_x64
<% else %>
RUN cd build/gmake_linux_zenity && make config=release_x64
<% end %>


# build libuv
WORKDIR /app/vendor/libuv
RUN cmake-wrap -S . -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_INSTALL_PREFIX=build/dist
RUN cd build && make -j 5 all install

# build llhttp
WORKDIR /app/vendor/llhttp
RUN mkdir -p build
RUN mkdir -p dist
RUN cmake-wrap -S . -B build -DCMAKE_BUILD_TYPE=Release -DLLHTTP_BUILD_STATIC_LIBS=ON -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_INSTALL_PREFIX=dist
RUN cd build && make -j 5 install

# build mbedtls
WORKDIR /app/vendor/mbedtls
RUN mkdir -p build
RUN cmake-wrap -S . -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=build/dist -DCMAKE_INSTALL_LIBDIR=lib -DENABLE_TESTING=OFF -DENABLE_PROGRAMS=OFF
RUN cd build && make -j 5 install

# build zlib
WORKDIR /app/vendor/zlib
RUN mkdir -p build
RUN cmake-wrap -S . -B build -DCMAKE_BUILD_TYPE=Release -DZLIB_BUILD_TESTING=OFF -DZLIB_BUILD_SHARED=OFF -DZLIB_INSTALL=OFF
RUN cd build && make -j 5

# build tlsuv
WORKDIR /app/vendor/tlsuv
COPY <<'FUCK' tlsuv.patch
#{Hokusai::Patches.tlsuv_patch}
FUCK

RUN git init
RUN git add .
RUN git apply tlsuv.patch

RUN cmake-wrap -S . -B build DMBEDCRYPTO_LIBRARY='../../vendor/mbedtls/build/dist/libmbedcrypto.a' \
  -DMBEDTLS_INCLUDE_DIRS='../../vendor/mbedtls/build/dist/include' \
  -DMBEDTLS_LIBRARY='../../vendor/mbedtls/build/dist/lib/libmbedtls.a' \
  -DMBEDX509_LIBRARY='../../vendor/mbedtls/build/dist/lib/libmbedx509.a' \
  -DBUILD_SHARED_LIBS=OFF \
  -DCMAKE_BUILD_TYPE=Release \
  -DTLSUV_HTTP=ON \
  -DTLSUV_TLSLIB=mbedtls \
  -DZLIB_INCLUDE='../../vendor/zlib' \
  -DZLIB_LIB="../../vendor/zlib/build/$ZLIBA" \
  -DLLHTTP_LIB='../../vendor/llhtp/dist/lib/libllhttp.a' \
  -DLLHTTP_INCLUDE='../../vendor/llhttp/dist/include' \
  -DTLSUV_LIBUV_LIB='../../vendor/libuv/libuv.a' \
  -DTLSUV_LIBUV_INCLUDE='../../vendor/libuv/build/dist/include' \
<% if os == "osx" %>\
  -DCMAKE_FRAMEWORK_PATH='/opt/osxcross/target/SDK/MacOSX11.3.sdk/System/Library/Frameworks' \
  -DCMAKE_EXE_LINKER_FLAGS='-framework Security'\
<% end %>\
  -DMBEDTLS_INCLUDE='../../vendor/mbedtls/build/dist/include/' 

RUN cd build && make -j 5 all 

WORKDIR /app
RUN mkdir -p /app/vendor/hokusai-pocket

COPY <<EOT /app/Brewfile
spec("hokusai-pocket-app") do
  task "build" do |args|
    def mrbc
      "vendor/mruby/build/host/bin/mrbc"
    end

<% if os.eql?("windows")%>
    def zlib
      "libzs.a"
    end

    def nfd
      "nfd.lib"
    end
<% else %>
    def zlib
      "libz.a"
    end

    def nfd
      "libnfd.a"
    end
<% end %>

<% if os.eql?("windows") %>
    def libs
      "-lws2_32 -lgdi32 -lwinmm -lcomctl32 -lcomdlg32 -lole32 -luuid -ldbghelp -liphlpapi -luserenv -lbcrypt -lcrypt32 -static -lwinpthread  -lsynchronization"
    end
<% elsif os.eql?("osx") %>
    def libs
      "-framework CoreVideo -framework Security -framework CoreAudio -framework AppKit -framework IOKit -framework Cocoa -framework GLUT -framework OpenGL"
    end
<% else %>
    def libs
      "-lGL -lm -lpthread -ldl -lrt -lX11"
    end
<% end %>
    def includes
      %w[
          vendor/tree-sitter/build/include 
          vendor/raylib/src 
          vendor/mruby/include
          vendor/mruby/build/host/include
          vendor/hp/grammar/tree_sitter
          vendor/hp/src
          vendor/hp/src/mruby-uv
          vendor/nfd/src/include
          vendor/libuv/include
          vendor/llhttp/include
          vendor/tlsuv/deps/uv_link_t/include
          vendor/tlsuv/build/generated
          vendor/tlsuv/include
          vendor/zlib
          vendor/hp/src/http
        ]
    end

    def mbedtls_libs
      %w[libmbedtls.a libmbedx509.a libmbedcrypto.a]
    end

    def links
      ln = %w[
        vendor/hp/grammar/src/parser.c
        vendor/hp/grammar/src/scanner.c
        vendor/hokusai-pocket/libhokusai.a
        vendor/mruby/build/platform/lib/libmruby.a 
        vendor/raylib/src/libraylib.a
        vendor/tree-sitter/build/lib/libtree-sitter.a
        vendor/libuv/build/dist/lib/libuv.a
      ] + ["vendor/nfd/build/lib/Release/x64/\#{nfd}"]

      ln << "vendor/tlsuv/build/libtlsuv.a"
      ln << "vendor/llhttp/dist/lib/libllhttp.a"

      mbedtls_libs.each do |lib|
        ln << "vendor/mbedtls/build/dist/lib/\#{lib}"
      end

      ln << "vendor/zlib/build/\#{zlib}"
      ln.join(" ")
    end

    def h_includes
      includes.map { |file| "-I../../\#{file}" }.join(" ")
    end

    def sources
      Dir.glob("vendor/hp/src/*.c")
    end

    def h_sources
      sources.map do |file|
        "../../\#{file}"
      end.join(" ")
    end

    def objs
      Dir.glob("vendor/hokusai-pocket/*.o").map do |file|
        File.basename(file)
      end.join(" ")
    end

    def build
      # build hokusai ruby proper...
      File.open("vendor/hp/mrblib/hokusai.rb", "w") { |io| io << ruby_file("vendor/hp/ruby/hokusai.rb") }
      mkdir("vendor/hokusai-pocket")

      command("\#{mrbc} -o vendor/hp/src/pocket.c -Bpocket ./vendor/hp/mrblib/hokusai.rb")

      ruby do
        code = File.read("vendor/hp/src/pocket.c")

        File.open("vendor/hp/src/pocket.c", "w") do |io|
          io.puts "#include <stdint.h>"
          io.puts "#include <pocket.h>"
          io.puts "#include <mruby.h>"
          io.puts "#include <mruby/irep.h>"
          io.puts "void load_pocket(mrb_state* mrb) {"
          io.puts code
          io.puts "mrb_load_irep(mrb, pocket);"
          io.puts "}"
        end

        File.open("vendor/hp/src/pocket.h", "w") do |io|
          io.puts "#ifndef MRB_HPOCKET_LIB"
          io.puts "#define MRB_HPOCKET_LIB"
          io.puts "#include <mruby.h>"
          io.puts "void load_pocket(mrb_state* mrb);"
          io.puts "#endif"
        end
      end

      # ugh, need separate libuv/raylib compilation units because of windows.h collisions
      loop_includes = %w[
        vendor/mruby/include
        vendor/mruby/build/host/include
        vendor/libuv/include
        vendor/tree-sitter/build/include
        vendor/hp/src
        vendor/hp/grammar/tree_sitter
      ].map { |inc| "-I../../\#{inc}" }.join(" ")

      command("${CC:-gcc} -O3 -Wall \#{loop_includes} -c ../../vendor/hp/src/mruby-uv/loop.c", chdir: "vendor/hokusai-pocket")
      # end building loop.o

      ruby do
        command("${CC:-gcc} -O3 -Wall \#{h_includes} -c #\{h_sources}", chdir: "vendor/hokusai-pocket")
        .forward_output(&on_output)
        .execute

        command("${AR:-ar} r libhokusai.a \#{objs}", chdir: "vendor/hokusai-pocket")
        .forward_output(&on_output)
        .execute
      end

      # build the app
      command("\#{mrbc} -o pocket-app.h -Bpocket_app pocket-app.rb")
      ruby do
        File.open("<%= outfile %>.c", "w") do |io|
          str = <<~C          
          #include <mruby.h>
          #include <mruby/array.h>
          #include <mruby/irep.h>

          #include <mruby_hokusai_pocket.h>
          #include <pocket.h>
          #include <pocket-app.h>

          int main(int argc, char* argv[])
          {
            mrb_state* mrb = mrb_open();
            mrb_mruby_hokusai_pocket_gem_init(mrb);
            if (mrb->exc) {
              mrb_print_error(mrb);
              return 1;
            } 

            int ai = mrb_gc_arena_save(mrb);
            mrb_value gemspec = mrb_load_irep(mrb, pocket_app);
            mrb_gc_arena_restore(mrb, ai);

            if (mrb->exc) {
              mrb_print_error(mrb);
              return 1;
            } 
            mrb_mruby_hokusai_pocket_gem_final(mrb);
            mrb_close(mrb);
          }
          C

          io << str
        end
      end

      app_includes = %w[
        vendor/raylib/src
        vendor/tree-sitter/build/include 
        vendor/mruby/include
        vendor/mruby/build/host/include
        .
        vendor/hokusai-pocket
        vendor/hp/src
        vendor/hp/src/mruby-uv
        vendor/nfd/src/include
        vendor/libuv/include
      ].map { |file| "-I\#{file}" }.join(" ")

      mkdir("bin")
      command("${CC:-gcc} -O3 -Wall \#{app_includes} -o bin/<%= outfile %> <%= outfile %>.c \#{links} \#{libs}")
    end
  end
end
EOT

WORKDIR /app

ADD build/pocket-app.rb .

<% if !extras.empty? %>
  <% extras.each do |extra| %>
    ADD <%= extra %> /app/<% extra %>
  <% end %>
<% end %>

<% if assets_path %>
  ADD <%= assets_path %> /app/bin/assets
<% end %>


RUN barista build

# export
FROM scratch
COPY --from=cross /app/bin/ /<%= outfile %>
HELL
  end
end

HP_SHADER_UNIFORM_FLOAT  = 0     # Shader uniform type: float
HP_SHADER_UNIFORM_VEC2   = 1     # Shader uniform type: vec2 (2 float)
HP_SHADER_UNIFORM_VEC3   = 2     # Shader uniform type: vec3 (3 float)
HP_SHADER_UNIFORM_VEC4   = 3     # Shader uniform type: vec4 (4 float)
HP_SHADER_UNIFORM_INT    = 4     # Shader uniform type: int
HP_SHADER_UNIFORM_IVEC2  = 5     # Shader uniform type: ivec2 (2 int)
HP_SHADER_UNIFORM_IVEC3  = 6     # Shader uniform type: ivec3 (3 int)
HP_SHADER_UNIFORM_IVEC4  = 7     # Shader uniform type: ivec4 (4 int)
HP_SHADER_UNIFORM_UINT   = 8     # Shader uniform type: unsigned int
HP_SHADER_UNIFORM_UIVEC2 = 9     # Shader uniform type: uivec2 (2 unsigned int)
HP_SHADER_UNIFORM_UIVEC3 = 10    # Shader uniform type: uivec3 (3 unsigned int)
HP_SHADER_UNIFORM_UIVEC4 = 11    # Shader uniform type: uivec4 (4 unsigned int)

# A backend agnostic library for authoring
# desktop applications
# @author skinnyjames
module Hokusai
  # Class for handling async work.
  class Work
    def initialize(receiver)
      @state = nil
      @receiver = receiver
      @on_execute_cb = nil
      @on_finished_cb = nil
    end

    def on_execute(state = nil, &block)
      @state = state
      @on_execute_cb = block
    end

    def on_finished(&block)
      @on_finished_cb = block
    end

    def execute(state)
      @on_execute_cb&.call(state)
    end

    def finish(receiver, value = nil)
      receiver.instance_exec(value, &@on_finished_cb)
    end
  end
  
  def self.http
    HTTP
  end

  def self.tmpdir
    @tmpdir || "."
  end

  def self.tmpdir=(val)
    @tmpdir = val
  end

  # Public: Access the font registry
  #
  # Returns a [Hokusai::FontRegistry](/api/Hokusai/FontRegistry)
  def self.fonts
    @fonts ||= FontRegistry.new
  end

  # Public: Access the texture registry
  # 
  # Returns a [Hokusai::TextureRegistry](/api/Hokusai/TextureRegistry)
  def self.textures
    @textures ||= TextureRegistry.new
  end

  # Public: Access the image registry
  # 
  # Returns a [Hokusai::ImageRegistry](/api/Hokusai/ImageRegistry)
  def self.images
    @images ||= ImageRegistry.new
  end

  # Public: Access the music registry
  # 
  # Returns a [Hokusai::MusicRegistry](/api/Hokusai/MusicRegistry)
  def self.musics
    @musics ||= MusicRegistry.new
  end

  # Public: close the current window
  #
  # Returns nothing
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

  # Public: Restores the current window
  #
  # Returns nothing
  def self.restore_window
    @on_restore_window&.call
  end

  # Public: Minimizes the current window
  #
  # Returns nothing
  def self.minimize_window
    @on_minimize_window&.call
  end

  # **Backend** Provides the minimize window callback
  def self.on_minimize_window(&block)
    @on_minimize_window = block
  end

  # Public: Maxmizes the current window
  #
  # Returns nothing
  def self.maximize_window
    @on_maximize_window&.call
  end

  # **Backend** Provides the maximize window callback
  def self.on_maximize_window(&block)
    @on_maximize_window = block
  end

  def self.on_resize_window(&block)
    @on_resize_window = block
  end

  def self.resize_window(width, height)
    @on_resize_window&.call(width, height)
  end

  # Public: Sets the window position on the screen
  #
  # x - the screen's x coordinate
  # y - the screen's y coordinate
  #
  # Returns nothing
  def self.set_window_position(x, y)
    @on_set_window_position&.call(x, y)
  end

  # **Backend:** Provides the window position callback
  def self.on_set_window_position(&block)
    @on_set_window_position = block
  end

  # **Backend:** Provides the mouse position callback
  def self.on_set_mouse_position(&block)
    @on_set_mouse_position = block
  end

  # Public: Sets the mouse position
  # 
  # mouse - a Hokusai::Mouse with the position set.
  def self.set_mouse_position(mouse)
    @on_set_mouse_position&.call(mouse)
  end

  # **Backend** Provides the can_render callback
  def self.on_can_render(&block)
    @on_renderable = block
  end

  # **Backend** Provides the open_file callback
  def self.on_open_file(&block)
    @on_open_file = block
  end

  # Public: Picks a file path to open using native file dialog
  # 
  # hash - options for native file dialog
  #        :filter - A comma delimited string of extensions to filter
  #
  # Examples
  # 
  #   if path = Hokusai.open_file(filter: "png,jpg,jpeg,gif")
  #     p File.read(path)
  #   end
  #
  def self.open_file(hash = {})
    hash.transform_keys!(&:to_s)

    @on_open_file&.call(hash)
  end

  # **Backend** Provides the save_file callback
  def self.on_save_file(&block)
    @on_save_file = block
  end

  # Public: Picks a file path to save using native file dialog
  #
  # hash - options for native file dialog
  #        :filter - A comma delimited string of extensions to filter
  #
  # Examples
  #
  #   if path = Hokusai.save_file(filter: "txt,md")
  #     File.open(path, "w") { |io| io << "Hello" }
  #   end
  #
  # Returns nothing
  def self.save_file(hash = {})
    hash.transform_keys!(&:to_s)

    @on_save_file&.call(hash)
  end

  # Public: Tells if a canvas is renderable (useful for pruning unneeded renders)
  # 
  # canvas - a Hokusai::Canvas
  #
  # Returns a boolean
  def self.can_render(canvas)
    @on_renderable&.call(canvas)
  end

  # **Backend** Provides set mouse cursor callback
  def self.on_set_mouse_cursor(&block)
    @on_set_mouse_cursor = block
  end

  # Public: Sets the mouse cursor from the available types:
  # 
  # type - A symbol representing the type.
  #        can be one of [:default, :arrow, :ibeam, :crosshair, :pointer, :none]
  #
  def self.set_mouse_cursor(type)
    @on_set_mouse_cursor&.call(type)
  end

  # **Backend** Provides copy callback
  def self.on_copy(&block)
    @on_copy = block
  end

  # Public: Copies text to clipboard
  #
  # text - the text to copy (String)
  #
  # Returns nothing
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

  # Internal: Copies state from one Hokusai::Block to another Hokusai::Block
  #           Used in hot reloading to preserve state between reloads
  #           You probably don't need this
  def self.copy_state(src, target)
    stack = [src]
    tstack = [target]

    while src_block = stack.pop
      if t_block = tstack.pop
        if stack.size > tstack.size
          # nodes have been removed
          # drop nodes until they match up again.
          while src_block.class != t_block.class
            src_block = stack.pop
          end

        elsif tstack.size > stack.size
          # nodes have been added
          # skip until they match up again
          while src_block.class != t_block.class
            t_block = tstack.pop
          end
        end

        if t_block.class == src_block.class 
          src_block.instance_variables.each do |var|
            unless var == :@node
              t_block.instance_variable_set(var, src_block.instance_variable_get(var))
            end
          end

          src_block.node.meta.props.each do |k, v|
            t_block.node.meta.set_prop(k, v)
          end
        end

        tstack.concat t_block.children.reverse
      end

      stack.concat src_block.children.reverse
    end
  end

  # **Backend** updates the state in a Hokusai::Block 
  # after running event handlers
  def self.update(block)
    stack = [block]
  
    while block = stack.pop
      block.update
    
      stack.concat block.children.reverse
    end
  end
end
