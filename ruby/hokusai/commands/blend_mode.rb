module Hokusai
  class Commands::BlendModeBegin < Commands::Base
    attr_reader :type

    # possible types
    # :alpha, :multiply, :additive, :colors
    def initialize(type)
      @type = type
    end

    def hash
      [self.class, type].hash
    end
  end

  class Commands::BlendModeEnd < Commands::Base;
    def hash
      [self.class].hash
    end
  end
end