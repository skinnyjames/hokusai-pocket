module Hokusai
  # Starts a Scale filter
  # Every command inside this filter
  # will be scaled to [x,y]
  class Commands::ScaleBegin < Commands::Base
    attr_reader :x, :y

    # @param [Float] width of scale
    # @param [Float] height of scale
    def initialize(x, y = x)
      @x = x
      @y = y
    end

    def hash
      [self.class, x, y].hash
    end
  end

  class Commands::ScaleEnd < Commands::Base;
    def hash
      [self.class].hash
    end
  end
end