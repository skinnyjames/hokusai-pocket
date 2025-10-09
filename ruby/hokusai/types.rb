require_relative "./types/primitives"
require_relative "./types/display"
require_relative "./types/touch"
require_relative "./types/mouse"
require_relative "./types/keyboard"

module Hokusai
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

    def support_touch!
      @touch ||= Touch.new

      self
    end

    def keyboard
      @keyboard ||= Keyboard.new
    end

    def mouse
      @mouse ||= Mouse.new
    end

    def hovered?(canvas)
      pos = mouse.pos
      pos.x >= canvas.x && pos.x <= canvas.x + canvas.width && pos.y >= canvas.y && pos.y <= canvas.y + canvas.height
    end
  end
end
