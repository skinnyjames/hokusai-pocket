module Hokusai
  # Internal: Command to render an Hokusai::Image
  class Commands::Image < Commands::Base
    attr_reader :x, :y, :width, :height, :image, :slice

    # Internal: constructor
    # 
    # image - a Hokusai::Image
    # x - x coordinate
    # y - y coordinate
    # width - width (float)
    # height - height (float)
    def initialize(image, x, y, width, height)
      @image = image
      @x = x
      @y = y
      @width = width
      @height = height
      @slice = nil
    end

    # Public: Specify a slice of the image to render
    #         Useful for spritesheets
    #         
    # rect - a [Hokusai::Rect](/api/Hokusai/Rect) which denotes where to pick from the image
    # 
    # Returns nothing
    def slice=(rect)
      raise Hokusai::Error.new("Argument must be a Hokusai::Rect") unless rect.is_a? Hokusai::Rect

      @slice = rect
    end

    def hash
      [self.class, x, y, width, height].hash
    end

    def cache
      [width, height].hash
    end
  end
end
