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
