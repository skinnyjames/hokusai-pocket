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
  # A proxy class for invoking various UI commands
  #
  # Invocations of commands are immediately sent to the backend
  # for drawing
  #
  # Used as part of the drawing api for Hokusai::Block
  class Commands
    attr_reader :queue

    def initialize
      @queue = []
    end

    # Draw a rectangle
    #
    # @param [Float] the x coordinate
    # @param [Float] the y coordinate
    # @param [Float] the width of the rectangle
    # @param [Float] height of the rectangle
    def rect(x, y, w, h)
      command = Commands::Rect.new(x, y, w, h)

      yield(command)

      queue << command
    end

    # Draw a circle
    #
    # @param [Float] x coordinate
    # @param [Float] y coordinate
    # @param [Float] radius of the circle
    def circle(x, y, radius)
      command = Commands::Circle.new(x, y, radius)

      yield(command)

      queue << command
    end

    # Draws an SVG
    #
    # @param [String] location of the svg
    # @param [Float] x coord
    # @param [Float] y coord
    # @param [Float] width of the svg
    # @param [Float] height of the svg
    def svg(source, x, y, w, h)
      command = Commands::SVG.new(source, x, y, w, h)

      yield(command)

      queue << command
    end

    # Invokes an image command
    # from a filename, at position {x,y} with `w`x`h` dimensions
    def image(source, x, y, w, h)
      queue << Commands::Image.new(source, x, y, w, h)
    end

    # Invokes a scissor begin command
    # at position {x,y} with `w`x`h` dimensions
    def scissor_begin(x, y, w, h)
      queue << Commands::ScissorBegin.new(x, y, w, h)
    end

    # Invokes a scissor stop command
    def scissor_end
      queue << Commands::ScissorEnd.new
    end

    def blend_mode_begin(type)
      queue << Commands::BlendModeBegin.new(type)
    end

    def blend_mode_end
      queue << Commands::BlendModeEnd.new
    end

    def shader_begin
      command = Commands::ShaderBegin.new

      yield command

      queue << command
    end

    def shader_end
      queue << Commands::ShaderEnd.new
    end

    def rotation_begin(x, y, deg)
      queue << Commands::RotationBegin.new(x, y, deg)
    end

    def rotation_end
      queue << Commands::RotationEnd.new
    end

    def scale_begin(*args)
      queue << Commands::ScaleBegin.new(*args)
    end

    def scale_end
      queue << Commands::ScaleEnd.new
    end

    def translation_Begin(x, y)
      queue << Commands::TranslationBegin.new
    end

    def translation_end
      queue << Commands::TranslationEnd.new
    end

    # def texture_begin(texture, x, y)
    #   commands << Commands::TextureBegin.new(texture, x, y)
    # end

    # def texture_end
    #   commands << Commands::TextureEnd.new
    # end

    def texture(texture, x, y)
      command = Commands::Texture.new(texture, x, y)

      yield command if block_given?

      queue << command
    end

    # Draws text
    #
    # @param [String] the text content
    # @param [Float] x coord
    # @param [Float] y coord
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