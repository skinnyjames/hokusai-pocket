module Hokusai
  class Commands::ScissorBegin < Commands::Base
    attr_reader :x, :y, :width, :height

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