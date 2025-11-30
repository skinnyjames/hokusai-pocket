module Hokusai
  class Commands::Texture < Commands::Base
    attr_reader :texture, :x, :y
    attr_accessor :width, :height, :flip, :repeat, :rotation

    def initialize(texture, x, y)
      @texture = texture
      @x = x
      @y = y
      @width = texture.width.to_f
      @height = texture.height.to_f
      @repeat = false
      @rotation = 0.0
      @flip = true
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