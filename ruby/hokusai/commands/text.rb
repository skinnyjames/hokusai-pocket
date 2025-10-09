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