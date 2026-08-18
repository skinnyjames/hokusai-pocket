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