module Hokusai
  class Commands::RotationBegin < Commands::Base
    attr_reader :x, :y, :degrees

    def initialize(x, y, deg)
      @x = x
      @y = y
      @degrees = deg
    end

    def hash
      [self.class, x, y, degrees].hash
    end
  end

  class Commands::RotationEnd < Commands::Base;
    def hash
      [self.class].hash
    end
  end
end