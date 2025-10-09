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
      @touch.tapped?
    end

    def swiped?
      @touch.swiped?
    end
    
    def longtapped?
      @touch.longtapped?
    end

    def longtapping?
      @touch.longtapping?
    end

    def touching?
      @touch.touching?
    end

    def duration
      @touch.duration
    end

    def direction
      @touch.direction
    end

    def distance
      @touch.distance
    end

    def angle
      @touch.angle
    end

    def position
      @touch.position
    end

    def last_position
      @touch.last_position
    end

    def touch_len
      @touch.touch_len
    end

    def touch_count
      @touch.touch_count
    end

    def timer
      @touch.timer
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

  class TapHoldEvent < TouchEvent
    name "taphold"

    def capture(block, canvas)
      if matches(block) && longtapped? && hovered(canvas) 
        captures << block
      end
    end
  end

  class PinchEvent < TouchEvent
    name "pinch"

    def capture(block, canvas)
      if false && matches(block)
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