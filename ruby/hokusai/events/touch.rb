# frozen_string_literal: true

module Hokusai
  class TouchEvent < Event
    attr_reader :input

    def initialize(input, state)
      @input = input
      @state = state
      @touch = input.touch
    end

    def tapped?
      @touch.tap?
    end

    def doubletapped?
      @touch.doubletap?
    end

    def swiped_right?
      @touch.swipe_right?
    end

    def swiped_up?
      @touch.swipe_up?
    end

    def swiped_left?
      @touch.swipe_left?
    end

    def swiped_down?
      @touch.swiped_down?
    end

    def swipe_direction
      case @touch.type
      when :swipe_left
        :left
      when :swipe_right
        :right
      when :swipe_up
        :up
      when :swipe_down
        :down
      end
    end

    def pinch_direction
      case @touch.type
      when :pinch_in
        :in
      when :pinch_out
        :out
      end
    end

    def pinched?
      pinch_direction == :in || pinch_direction == :out
    end

    def swiped?
      swiped_right? || swiped_left? || swiped_up? || swiped_down?
    end

    def hold?
      @touch.hold?
    end
    
    def duration
      @touch.hold_duration
    end

    def pos
      @touch.pos
    end

    def drag
      @touch.drag
    end

    def pinch
      @touch.pinch
    end

    def hovered(canvas)
      input.hovered?(canvas)
    end

    def to_json
      {
        keypress: {
          hold: hold,
          hold_duration: hold_duration.to_s,
        }
      }.to_json
    end
  end

  class TapEvent < TouchEvent
    name "tap"

    def capture(block, canvas)
      if matches(block) && tap? && hovered(canvas) 
        captures << block
      end
    end
  end

  class DragEvent < TouchEvent
    name "drag"

    def capture(block, canvas)
      if matches(block) && @touch.drag?
        captures << block
      end
    end
  end

  class TapHoldEvent < TouchEvent
    name "taphold"

    def capture(block, canvas)
      if matches(block) && hold? && @touch.hold_duration > 0.3 && hovered(canvas) 
        captures << block
      end
    end
  end

  class PinchOutEvent < TouchEvent
    name "pinchout"

    def capture(block, canvas)
      if pinch_direction == :out && matches(block)
        captures << block
      end
    end
  end

  class PinchInEvent < TouchEvent
    name "pinchin"

    def capture(block, canvas)
      if pinch_direction == :in && matches(block)
        captures << block
      end
    end
  end

  class SwipeEvent < TouchEvent
    name "swipe"

    def capture(block, canvas)
      if swiped? && matches(block)
        captures << block
      end
    end
  end
end