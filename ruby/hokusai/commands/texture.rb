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