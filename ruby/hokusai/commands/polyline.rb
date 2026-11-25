module Hokusai
  # Internal: Command to draw a polyline.
  class Commands::Polyline < Commands::Base
    attr_reader :coords, :color
    attr_accessor :width, :type

    # Internal: Line constructor
    # 
    # coords - array of coordinates
    def initialize(coords)
      @coords = coords
      @type = :linear # :bezier, :linear, :bspline, :catmullrom
      @color = Color.new(255, 0, 0, 255)
      @width = 2.0
    end

    def hash
      [self.class, width, type, color.hash].hash
    end

    def valid?
      n = coords.size
      case type
      when :linear then n >= 2
      when :bezier then n >= 4 && ((n - 1) % 3).zero?
      when :bspline, :catmullrom then n >= 4
      else false
      end
    end

    def validate
      raise Hokusai::Error.new("Invalid #{type} polyline (#{coords.size} points)") unless valid?
    end

    # Public: sets the polyline color.
    # 
    # value - a Hokusai::Color or Array of Int
    #
    # Returns nothing
    def color=(value)
      case value
      when Color
        @color = value
      when Array
        @color = Color.new(value[0], value[1], value[2], value[3] || 255)
      end

      self
    end
  end
end
