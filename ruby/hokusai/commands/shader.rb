module Hokusai
  # Starts a Shader filter
  # Every command inside this filter
  # will be applied with this shader
  class Commands::ShaderBegin < Commands::Base
    attr_reader :vertex_shader, :fragment_shader, :uniforms

    def initialize
      @uniforms = {}
      @vertex_shader =  nil
      @fragment_shader = nil
      @textures = {}
    end

    # Set a Raylib style vertex shader
    # @param [String] vertex shader string
    def vertex_shader=(content)
      @vertex_shader = content
    end

    # Set a Raylib style vertex shader
    # @param [String] vertex shader string
    def fragment_shader=(content)
      @fragment_shader = content
    end

    # Set Uniforms to be used in the shaders
    # @param [Hash] a key value hash where 
    #   the key is a String with the uniform name
    #   the value is an array of [value, type]
    # Example:
    # command.uniforms = { "time" => [0.22, HP_SHADER_UNIFORM_FLOAT], "rgba" => [[0,0,0,244], HP_SHADER_UNIFORM_IVEC4]}
    def uniforms=(values)
      @uniforms = values
    end

    # Provide the shader with Hokusai::Textures
    # @param [Hash] a hash where
    #   the key is a String with the texture name
    #   the value is a Hokusai::Texture
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

  # Stops a shader filter
  class Commands::ShaderEnd < Commands::Base
    def hash
      [self.class].hash
    end
  end
end