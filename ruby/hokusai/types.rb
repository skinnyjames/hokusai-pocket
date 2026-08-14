require_relative "./types/primitives"
require_relative "./types/display"
require_relative "./types/touch"
require_relative "./types/mouse"
require_relative "./types/keyboard"

module Hokusai
  # Internal: Manages external input.  Populated from MRuby/Raylib backend
  class Input
    attr_accessor :keyboard_override
    attr_reader :raw, :touch

    def hash
      [self.class, mouse.pos.x, mouse.pos.y, mouse.scroll, mouse.left.clicked, mouse.left.down, mouse.left.up].hash
    end

    def initialize
      @touch = nil
      @keyboard_override = false
    end

    # Internal: Collect touch input
    def support_touch!
      @touch ||= Touch.new

      self
    end

    # Internal: Keyboard input
    # 
    # Returns [Hokusai::Keyboard](/api/Hokusai/Keyboard)
    def keyboard
      @keyboard ||= Keyboard.new
    end

    # Internal: Mouse input
    # 
    # Returns [Hokusai::Mouse](/api/Hokusai/Mouse)
    def mouse
      @mouse ||= Mouse.new
    end

    # Internal: check if mouse is over (canvas)
    # 
    # canvas - a Hokusai::Canvas
    # 
    # Returns boolean
    def hovered?(canvas)
      pos = mouse.pos
      pos.x >= canvas.x && pos.x <= canvas.x + canvas.width && pos.y >= canvas.y && pos.y <= canvas.y + canvas.height
    end
  end
end
