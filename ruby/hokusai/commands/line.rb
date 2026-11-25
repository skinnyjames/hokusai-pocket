module Hokusai
  # Internal: Command to draw a line.
  class Commands::Line < Commands::Base
    attr_reader :x, :y, :ex, :ey, :color
    attr_accessor :width

    # Internal: Line constructor
    # 
    # x - x coordinate
    # y - y coordinate
    # ex - end x coordinate
    # ey - end y coordinate
    def initialize(x, y, ex, ey)
      @x = x.to_f
      @y = y.to_f
      @ex = ex.to_f
      @ey = ey.to_f
      @color = Color.new(255, 0, 0, 255)
      @width = 2.0
    end

    def hash
      [self.class, x, y, ex, ey, width, color.hash].hash
    end

    # Public: sets the line color.
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
  end
end
