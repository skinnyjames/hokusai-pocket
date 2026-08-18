module Hokusai
  # Public: Represents a Keyboard Event
  class KeyboardEvent < BaseEvent
    attr_reader :input

    def initialize(input, state)
      @input = input
      @state = state
      @keyboard = input.keyboard
    end

    # Public: is the key printable to the screen?
    # 
    # Returns boolean
    def printable?
      @keyboard.printable?
    end
    
    # Public: array of pressed keys
    # 
    # Returns Array(Hash)
    def pressed
      @keyboard.pressed
    end

    # Public: array of released keys
    # 
    # Returns Array(Hash)
    def released
      @keyboard.released
    end

    # Public: array of keys currently being held down
    # 
    # Returns Array(Hash)
    def down
      @keyboard.down
    end

    # Public: the pressed/released character
    # 
    # Returns String
    def char
      @keyboard.char
    end
    
    # Public: the pressed/released key symbol
    # 
    # Returns Symbol
    def symbol
      @keyboard.symbol
    end

    # Public: the pressed/released key code
    # 
    # Returns Integer
    def code
      @keyboard.code
    end

    # Public: shift being pressed/released?
    # 
    # Returns boolean
    def shift
      @keyboard.shift
    end

    # Public: is super being pressed/released?
    # 
    # Returns boolean
    def super
      @keyboard.send(:super)
    end

    # Public: is ctrl being pressed/released?
    #
    # Returns boolean
    def ctrl
      @keyboard.ctrl
    end

    # Public: is alt being pressed/released?
    #
    # Returns boolean
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

  # Public: A [Hokusai::KeyboardEvent](/api/Hokusai/KeyboardEvent) where a key has been released.
  # 
  class KeyUpEvent < KeyboardEvent
    name "keyup"

    # Public: The released key in symbol from
    #
    # Returns Symbol
    def key
      released[0]&.[](:symbol)
    end

    # Public: the pressed/released key code
    # 
    # Returns Integer
    def code
      released[0]&.[](:code)
    end

    # Public: the pressed/released character
    # 
    # Returns String
    def char
      released[0]&.[](:char)
    end

    def capture(block, canvas)
      add_capture(block) if matches(block) && released.size > 0
    end
  end

  # Public: A [Hokusai::KeyboardEvent](/api/Hokusai/KeyboardEvent) where a key is being pressed.
  # 
  class KeyDownEvent < KeyboardEvent
    name "keydown"
    
    # Public: The key in symbol from
    #
    # Returns Symbol
    def key
      down[0]&.[](:symbol)
    end

    # Public: the key code
    # 
    # Returns Integer
    def code
      down[0]&.[](:code)
    end

    # Public: the character
    # 
    # Returns String
    def char
      down[0]&.[](:char)
    end

    def capture(block, _)
      return unless matches(block) && down.size > 0
      
      add_capture(block)
    end
  end

  # Public: A [Hokusai::KeyboardEvent](/api/Hokusai/KeyboardEvent) where a key has been pressed/released.
  # 
  class KeyPressEvent < KeyboardEvent
    name "keypress"

    # Public: The key in symbol from
    #
    # Returns Symbol
    def key
      pressed[0]&.[](:symbol)
    end

    # Public: the key code
    # 
    # Returns Integer
    def code
      pressed[0]&.[](:code)
    end

    # Public: the character
    # 
    # Returns String
    def char
      pressed[0]&.[](:char)
    end

    def capture(block, _)
      return unless matches(block) && pressed.size > 0
      add_capture(block)
    end
  end
end