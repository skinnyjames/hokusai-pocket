module Hokusai
  # Internal: tracks drag touch input state
  class Drag
    attr_accessor :pos, :angle
    def initialize
      @pos = Vec2.new(0.0, 0.0)
      @angle = 0
    end
  end

  class Pinch < Drag; end

  EVENTS = {
    0 => :none,
    1 => :tap,
    2 => :doubletap,
    4 => :hold,
    8 => :drag,
    16 => :swipe_right,
    32 => :swipe_left,
    64 => :swipe_up,
    128 => :swipe_down,
    256 => :pinch_in,
    512 => :pinch_out,
    1024 => :released,
  }

  # Internal: Touch management. Populated from MRuby/Raylib layer
  class Touch
    attr_accessor :type, :hold_duration, :drag, :pinch, :down, :up,
                  :pos, :count
    def initialize
      @type = :none
      @pos = Vec2.new(0.0, 0.0)
      @count = 0
      @hold_duration = 0.0
      @drag = Drag.new
      @pinch = Pinch.new
    end

    # Internal: Not touching?
    # 
    # Returns boolean
    def released?
      @type == :released || @type == :none
    end

    def set(event)
      @type = EVENTS[event]
    end

    EVENTS.values.each do |event|
      define_method("#{event}?") do
        @type == event
      end
    end
  end
end
