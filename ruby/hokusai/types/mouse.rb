module Hokusai
  # Public: Represenation of mouse button state
  #  
  # Examples
  # 
  #   # from input
  #   input.mouse.left.up # => false
  #   input.mouse.left.down # => true
  #   input.mouse.left.clicked # => true
  #   input.mouse.left.released # => false
  #   
  class MouseButton
    attr_accessor :up, :down, :clicked, :released

    def initialize
      @up = false
      @down = false
      @clicked = false
      @released = false
    end
  end

  # Public: Representation of mouse state
  class Mouse  
    # Public: A [Hokusai::Vec2](/api/Hokusai/Vec2) holding the mouse position
    attr_accessor :pos

    # Public: A [Hokusai::Vec2](/api/Hokusai/Vec2) holding the mouse delta
    attr_accessor :delta

    # Public: A float containing the mouse scroll
    attr_accessor :scroll

    # Public: A float containing the mouse scroll delta
    attr_accessor :scroll_delta

    attr_accessor :left, :right, :middle

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
