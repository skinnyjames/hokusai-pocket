# frozen_string_literal: true

module Hokusai
  class KeyboardEvent < Event
    attr_reader :input

    def initialize(input, state)
      @input = input
      @state = state
      @keyboard = input.keyboard
    end

    def printable?
      @keyboard.printable?
    end
    
    def pressed
      @keyboard.pressed
    end

    def released
      @keyboard.released
    end

    def char
      @keyboard.char
    end
    
    def symbol
      @keyboard.symbol
    end

    def code
      @keyboard.code
    end

    def shift
      @keyboard.shift
    end

    def super
      @keyboard.send(:super)
    end

    def ctrl
      @keyboard.ctrl
    end

    def alt
      @keyboard.alt
    end

    def hovered(canvas)
      input.hovered?(canvas)
    end

    def to_json
      {
        keypress: {
          keycode: code,
          char: char.to_s,
          super: self.super,
          control: ctrl,
          shift: shift,
          alt: alt
        }
      }.to_json
    end
  end

  class KeyUpEvent < KeyboardEvent
    name "keyup"

    def key
      released[0]&.[](:symbol)
    end

    def code
      released[0]&.[](:code)
    end

    def char
      released[0]&.[](:char)
    end

    def capture(block, canvas)
      add_capture(block) if matches(block) && released.size > 0
    end
  end

  class KeyPressEvent < KeyboardEvent
    name "keypress"

    def key
      pressed[0]&.[](:symbol)
    end

    def code
      pressed[0]&.[](:code)
    end

    def char
      pressed[0]&.[](:char)
    end

    def capture(block, _)
      return unless matches(block) && pressed.size > 0
      add_capture(block)
    end
  end
end