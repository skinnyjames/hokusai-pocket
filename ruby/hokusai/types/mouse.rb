# frozen_string_literal: true

module Hokusai
  class MouseButton
    attr_accessor :up, :down, :clicked, :released

    def initialize
      @up = false
      @down = false
      @clicked = false
      @released = false
    end
  end

  class Mouse
    attr_reader :pos, :delta, :left, :right, :middle, :scroll
    attr_accessor :scroll_delta

    def initialize
      @pos = Vec2.new(0.0, 0.0)
      @delta = Vec2.new(0.0, 0.0)
      @scroll = 0.0
      @scroll_delta = 0.0
      @left = MouseButton.new
      @middle = MouseButton.new
      @right = MouseButton.new
    end

    def scroll=(val)
      last = scroll
      new_y = (last >= val) ? last - val : val - last
      self.scroll_delta = new_y
      @scroll = val
    end
  end
end
