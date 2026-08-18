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