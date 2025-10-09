module Hokusai
  class Commands::ScaleBegin < Commands::Base
    attr_reader :x, :y

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