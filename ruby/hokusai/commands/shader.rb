module Hokusai
  class Commands::ShaderBegin < Commands::Base
    attr_reader :vertex_shader, :fragment_shader, :uniforms

    def initialize
      @uniforms = {}
      @vertex_shader =  nil
      @fragment_shader = nil
      @textures = {}
    end

    def vertex_shader=(content)
      @vertex_shader = content
    end

    def fragment_shader=(content)
      @fragment_shader = content
    end

    def uniforms=(values)
      @uniforms = values
    end

    def textures=(values)
      @textures = values
    end

    def textures
      @textures.transform_keys(&:to_s)
    end

    def uniforms
      @uniforms.transform_keys!(&:to_s)
    end

    def hash
      [self.class, vertex_shader, fragment_shader].hash
    end
  end

  class Commands::ShaderEnd < Commands::Base
    def hash
      [self.class].hash
    end
  end
end