module Hokusai
  # An class representing a Mouse event
  class MouseEvent < BaseEvent
    attr_reader :input, :state

    def initialize(input, state)
      @input = input
      @mouse = input.mouse
      @left = @mouse.left
      @right = @mouse.right
      @middle = @mouse.middle
      @state = state
    end

    def mouse
      @mouse
    end

    # Public: the x,y coordinates of the mouse
    # 
    # Returns Hokusai::Vec2
    def pos
      mouse.pos
    end

    # Public: the x,y delta coordinates
    # 
    # Returns Hokusai::Vec2
    def delta
      mouse.delta
    end

    # Public: the scroll amount
    # 
    # Returns Float
    def scroll
      mouse.scroll
    end

    # Public: the scroll delta value
    # 
    # Returns Float
    def scroll_delta
      mouse.scroll_delta
    end

    # Public: the details of the left mouse button
    # 
    # Returns [Hokusai::MouseButton](/api/Hokusai/MouseButton)
    def left
      @left
    end

    # Public: the details of the middle mouse button
    # 
    # Returns [Hokusai::MouseButton](/api/Hokusai/MouseButton)    
    def right
      @right
    end

    # Public: the details of the right mouse button
    # 
    # Returns [Hokusai::MouseButton](/api/Hokusai/MouseButton)    
    def middle
      @middle
    end

    def to_json
      hash = {}
      hash[:pos] = { x: pos.x, y: pos.y }

      [:left, :right, :middle].each do |button|
        hash[button] = {
          down: send(button).down,
          up: send(button).up,
          clicked: send(button).clicked,
          released: send(button).released
        }
      end

      hash[:scroll] = scroll
      hash[:scroll_delta] = scroll_delta

      hash.to_json
    end

    protected

    def hovered(canvas)
      input.hovered?(canvas)
    end
  end

  # Triggered when a mouse move occurs
  class MouseMoveEvent < MouseEvent
    name "mousemove"

    # Captured if the block is listening for @mousemove
    def capture(block, canvas)
      add_evented_styles(block) if hovered(canvas)

      if matches(block)
        add_capture(block)
      end
    end
  end

  # Public: Triggered when left mouse click occurs
  class ClickEvent < MouseEvent
    name "click"

    # Internal: Captured if the block is listening for @click 
    #           and the left mouse clicks the block geometry
    def capture(block, canvas)
      if left.clicked && clicked(canvas)
        block.node.meta.focus

        add_evented_styles(block) if hovered(canvas)

        if matches(block)
          add_capture(block)
        end
      elsif left.clicked
        block.node.meta.blur
      end
    end

    def clicked(canvas)
      left.clicked && input.hovered?(canvas)
    end
  end

  # Public: Triggered when left mouse button is up
  class MouseUpEvent < MouseEvent
    name "mouseup"

    def capture(block, canvas)
      add_evented_styles(block) if left.up && hovered(canvas)

      if left.up && matches(block)
        add_capture(block)
      end
    end
  end

  # Public: Triggered when left mouse button is down
  class MouseDownEvent < MouseEvent
    name "mousedown"

    def capture(block, canvas)
      add_evented_styles(block) if left.down && hovered(canvas)

      if left.down && matches(block)
        add_capture(block)
      end
    end
  end

  # Public: Triggered when mouse wheel is scrolled
  class WheelEvent < MouseEvent
    name "wheel"

    def capture(block, canvas)
      add_evented_styles(block) if scroll_delta != 0.0

      if matches(block) && scroll_delta != 0.0
        add_capture(block)
      end
    end
  end

  # Public: Triggered when mouse cursor is over a block
  class HoverEvent < MouseEvent
    name "hover"

    def capture(block, canvas)
      add_evented_styles(block) if hovered(canvas)

      add_capture(block)
    end

    def bubble
      while block = captures.pop
        block.emit(name, self)

        cursor = block.node.meta.get_prop(:cursor)&.to_sym

        if !state.set && cursor == :manual
          state.set = true
        end

        if !state.set && cursor && cursor != :manual
          Hokusai.set_mouse_cursor(cursor)
          state.set = true
        end

        break if stopped
      end

      if !state.nil? && !state.set
        Hokusai.set_mouse_cursor(:default)
      end
    end
  end

  # Public: Triggered when mouse cursor leaves a block
  class MouseOutEvent < MouseEvent
    name "mouseout"

    def capture(block, canvas)
      add_capture(block) if matches(block)

      if left.clicked && !clicked(canvas)
        block.node.meta.blur
      end
    end

    def clicked(canvas)
      left.clicked && input.hovered?(canvas)
    end
  end
end
