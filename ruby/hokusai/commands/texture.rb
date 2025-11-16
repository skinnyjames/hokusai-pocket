module Hokusai
  class Commands::Texture < Commands::Base
    attr_reader :texture, :x, :y, :rotation, :scale

    def initialize(texture, x, y)
      @texture = texture
      @x = x
      @y = y
      @rotation = 0.0
      @scale = 1.0
    end
 
    def rotation=(value)
      @rotation = value
    end

    def scale=(value)
      @scale = value
    end

    def hash
      [self.class, width, height].hash
    end
  end

  class Commands::TextureBegin < Commands::Base
    attr_reader :texture

    def initialize(texture)
      @texture = texture
    end
  end

  class Commands::TextureEnd < Commands::Base; end
end