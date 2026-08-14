require_relative "./commands/base"
require_relative "./commands/circle"
require_relative "./commands/image"
require_relative "./commands/rect"
require_relative "./commands/scissor"
require_relative "./commands/text"
require_relative "./commands/shader"
require_relative "./commands/texture"
require_relative "./commands/rotation"
require_relative "./commands/scale"
require_relative "./commands/translation"
require_relative "./commands/blend_mode"

module Hokusai
  # Public: A proxy class for invoking various UI commands
  #          Invocations of commands are immediately sent to the backend for drawing
  #          Used as part of the drawing api for Hokusai::Block
  class Commands
    attr_reader :queue

    def initialize
      @queue = []
    end

    def hash
      @queue.hash
    end

    # Public: Draw a rectangle.  Yields a [Commands::Rectangle](/api/Hokusai/Commands/Rectangle)
    #
    # x - the x coordinate
    # y - the y coordinate
    # width - the width of the rectangle
    # height - height of the rectangle
    # 
    def rect(x, y, w, h)
      command = Commands::Rectangle.new(x, y, w, h)

      yield(command)

      queue << command
    end

    # Public: Draw a circle.  Yields a [Commands::Circle](/api/Hokusai/Commands/Circle)
    #
    # x - x coordinate (Float)
    # y - y coordinate (Float)
    # radius - radius of the circle (Float)
    def circle(x, y, radius)
      command = Commands::Circle.new(x, y, radius)

      yield(command)

      queue << command
    end

    # Public: Draws an image.  Yields a [Commands::Image](/api/Hokusai/Commands/Image)
    # 
    # image - a Hokusai::Image
    # x - x coordinate (Float)
    # y - y coordinate (Float)
    # width - width (Float)
    # height - height (Float)
    def image(source, x, y, w, h)
      command = Commands::Image.new(source, x, y, w, h)

      yield(command) if block_given?

      queue << command
    end

    # Public: Starts a scissor region
    # 
    # x - x coordinate (Float)
    # y - y coordinate (Float)
    # width - width (Float)
    # height - height (Float)
    def scissor_begin(x, y, w, h)
      queue << Commands::ScissorBegin.new(x, y, w, h)
    end

    # Public: ends scissor region
    def scissor_end
      queue << Commands::ScissorEnd.new
    end

    # Public: starts blend mode 
    # 
    # type - one of the values [:alpha, :multiply, :additive, :colors]
    def blend_mode_begin(type)
      queue << Commands::BlendModeBegin.new(type)
    end

    # Public: ends blend mode
    def blend_mode_end
      queue << Commands::BlendModeEnd.new
    end

    # Public: starts a GLSL shader.  Yields a [Commands::ShaderBegin](/api/Hokusai/Commands/ShaderBegin)
    def shader_begin
      command = Commands::ShaderBegin.new

      yield command

      queue << command
    end

    # Public: ends a shader
    def shader_end
      queue << Commands::ShaderEnd.new
    end

    # Public: starts a rotation
    # 
    # x - x coordinate (Float)
    # y - y coordinate (Float)
    # deg - degress to rotate (Integer)
    def rotation_begin(x, y, deg)
      queue << Commands::RotationBegin.new(x, y, deg)
    end

    # Public: ends a rotation
    def rotation_end
      queue << Commands::RotationEnd.new
    end

    # Public: starts a scale command
    def scale_begin(*args)
      queue << Commands::ScaleBegin.new(*args)
    end

    # Public: ends scaling
    def scale_end
      queue << Commands::ScaleEnd.new
    end

    # Public: Starts a 2D translation
    # x - x coordinate (Float)
    # y - y coordinate (Float)
    def translation_begin(x, y)
      queue << Commands::TranslationBegin.new(x, y)
    end

    # Public: Ends a 2D translation
    def translation_end
      queue << Commands::TranslationEnd.new
    end

    # Public: Draws a texture
    # 
    # texture - A Hokusai::Texture
    # x - x coordinate (Float)
    # y - y coordinate (Float)
    def texture(texture, x, y)
      command = Commands::Texture.new(texture, x, y)

      yield command if block_given?

      queue << command
    end

    # Public: Draws text.  Yields a [Commands::Text](/api/Hokusai/Commands/Text)
    #
    # content - the text content
    # x - x coord (Float)
    # y - y coord (Float)
    def text(content, x, y)
      command = Commands::Text.new(content, x, y)
      yield command

      queue << command
    end

    def execute
      queue.each(&:draw)
    end

    def clear!
      queue.clear
    end
  end
end