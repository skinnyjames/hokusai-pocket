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
