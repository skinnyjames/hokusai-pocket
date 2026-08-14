module Hokusai
  # Internal: Starts a BlendMode filter where every command inside this filter
  #           will be applied with the selected blend mode
  class Commands::BlendModeBegin < Commands::Base
    attr_reader :type

    # Internal: constructor
    #   type - one of the values [:alpha, :multiply, :additive, :colors]
    def initialize(type)
      @type = type
    end

    def hash
      [self.class, type].hash
    end
  end

  # Internal: Stops a BlendMode filter
  class Commands::BlendModeEnd < Commands::Base;
    def hash
      [self.class].hash
    end
  end
end