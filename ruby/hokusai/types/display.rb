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