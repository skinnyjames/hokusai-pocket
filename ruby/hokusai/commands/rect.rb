module Hokusai
  # Internal: Command to render a rectangle
  class Commands::Rectangle < Commands::Base
    attr_reader :x, :y, :width, :height,
                :rounding, :color, :outline,
                :outline_color, :padding, :gradient

    # @param [Float] start x
    # @param [Float] start y
    # @param [Float] rect width
    # @param [Float] rect height
    def initialize(x, y, width, height)
      @x = x.to_f
      @y = y.to_f
      @width = width.to_f
      @height = height.to_f
      @outline = Outline.default
      @rounding = 0.0
      @color = Color.new(255, 255, 255, 0)
      @outline_color = Color.new(0, 0, 0, 0)
      @padding = Padding.new(0.0, 0.0, 0.0, 0.0)
      @gradient = nil
    end

    def hash
      [self.class, x, y, width, height, rounding, color.hash, outline.hash, outline_color.hash, padding.hash].hash
    end

    # Modifies the parameter *Canvas*
    # to offset the boundary with
    # this rectangle's computed geometry
    def trim_canvas(canvas)
      x, y, w, h = background_boundary

      canvas.x = x + padding.left + outline.left
      canvas.y = y + padding.top + outline.top
      canvas.width = w - (padding.left + padding.right + outline.left + outline.right)
      canvas.height = h - (padding.top + padding.bottom + outline.top + outline.bottom)

      canvas
    end

    # Shorthand for #width
    def w
      width
    end

    # Shorthand for #height
    def h
      height
    end

    def gradient=(colors)
      unless colors.is_a?(Array) && colors.size == 4 && colors.all? { |color| color.is_a?(Hokusai::Color) }
        raise Hokusai::Error.new("Gradient must be an array of 4 Hokusai::Color")
      end

      @gradient = colors
    end

    # Public: Sets padding for the rectangle
    # 
    # value - a [Hokusai::Padding](/api/Hokusai/Padding) object
    # 
    # Returns self
    def padding=(value)
      case value
      when Padding
        @padding = value
      else
        @padding = Padding.convert(value)
      end

      self
    end

    # Public: Set outline for rect
    # 
    # value - a [Hokusai::Outline](/api/Hokusai/Outline) object
    def outline=(outline)
      @outline = outline

      self
    end

    # Public: Set outline color
    # 
    # value - a [Hokusai::Color](/api/Hokusai/Color) object
    def outline_color=(value)
      case value
      when Color
        @outline_color = value
      when Array
        @outline_color = Color.new(value[0], value[1], value[2], value[3] || 255)
      else
        raise "Basd color"
      end

      self
    end

    # Public: Set fill color
    # 
    # value - a [Hokusai::Color](/api/Hokusai/Color) object
    # 
    # Returns self
    def color=(value)
      case value
      when Color
        @color = value
      when Array
        @color = Color.new(value[0], value[1], value[2], value[3] || 255)
      end

      self
    end

    # Public: sets rounding
    # 
    # amount - a float value between 0 and 1
    # 
    # Returns self
    def round=(amount)
      @rounding = amount

      self
    end

    # Public: returns true if the rectangle has any padding
    def padding?
      [padding.t, padding.r, padding.b, padding.l].any? do |p|
        p != 0.0
      end
    end


    def boundary
      [x, y, width, height]
    end

    # Public: get the rect dimensions after padding and outline applied
    # 
    # Returns Array(Float)
    def background_boundary
      nx = x.dup
      ny = y.dup
      nw = width.dup
      nh = height.dup

      if outline.top > 0.0
        ny += outline.top
        nh -= outline.top
      end

      if outline.left > 0.0
        nx += outline.left
        nw -= outline.left
      end

      if outline.bottom > 0.0
        nh -= outline.bottom
      end

      if outline.right > 0.0
        nw -= outline.right
      end

      [nx, ny, nw, nh]
    end

    # Public: Does this rect have any outlines?
    def outline?
      outline.present?
    end

    # Public: Is the rect outline uniform?
    def outline_uniform?
      outline.uniform?
    end
  end
end