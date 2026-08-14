module Hokusai
  # Internal: Starts a Rotation filter
  #           Every command inside this filter will be applied with the rotation
  class Commands::RotationBegin < Commands::Base
    attr_reader :x, :y, :degrees

    # Internal: constructor 
    # 
    # x - x rotation coord
    # y - y rotation coord
    # deg - degress to rotate
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