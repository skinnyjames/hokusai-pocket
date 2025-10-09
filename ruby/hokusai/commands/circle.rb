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
