module Hokusai
  # Starts a Scissor filter
  # Every command inside this filter
  # will apply the pruning area
  # This is useful for panels and scrollable areas
  class Commands::ScissorBegin < Commands::Base
    attr_reader :x, :y, :width, :height

    # @param [Float] start x
    # @param [Float] start y
    # @param [Float] scissor width
    # @param [Float] scissor height
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