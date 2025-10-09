# frozen_string_literal: true

module Hokusai
  KEY_CODES = { 
    null: 0, apostrophe: 39, comma: 44, minus: 45, period: 46,
    slash: 47, zero: 48, one: 49, two: 50, three: 51, four: 52,
    five: 53, six: 54, seven: 55, eight: 56, nine: 57, semicolon: 59, 
    equal: 61, a: 65, b: 66, c: 67, d: 68, e: 69, f: 70, g: 71, h: 72, 
    i: 73, j: 74, k: 75, l: 76, m: 77, n: 78, o: 79, p: 80, q: 81, r: 82, 
    s: 83, t: 84, u: 85, v: 86, w: 87, x: 88, y: 89, z: 90, left_bracket: 91, 
    backslash: 92, right_bracket: 93, grave: 96, space: 32, escape: 256, 
    enter: 257, tab: 258, backspace: 259, insert: 260, delete: 261, right: 262, 
    left: 263, down: 264, up: 265, page_up: 266, page_down: 267, home: 268, end: 269, 
    caps_lock: 280, scroll_lock: 281, num_lock: 282, print_screen: 283, pause: 284, 
    f1: 290, f2: 291, f3: 292, f4: 293, f5: 294, f6: 295, f7: 296, f8: 297, 
    f9: 298, f10: 299, f11: 300, f12: 301, left_shift: 340, left_control: 341, 
    left_alt: 342, left_super: 343, right_shift: 344, right_control: 345, right_alt: 346, 
    right_super: 347, kb_menu: 348, kp_0: 320, kp_1: 321, kp_2: 322, kp_3: 323, 
    kp_4: 324, kp_5: 325, kp_6: 326, kp_7: 327, kp_8: 328, kp_9: 329, kp_decimal: 330, 
    kp_divide: 331, kp_multiply: 332, kp_subtract: 333, kp_add: 334, kp_enter: 335, 
    kp_equal: 336, back: 4, menu: 5, volume_up: 24, volume_down: 25
  }

  class Keyboard
    attr_accessor :shift, :control, :super, :alt
    attr_reader :keys, :pressed, :released

    def printable?
      [
        :space, :tab, :apostrophe, :comma, :minus, :period,
        :slash,
        :zero, :one, :two, :three, :four, :five, :six, 
        :seven, :eight, :nine, :semicolon, 
        :a, :b, :c, :d, :e, :f, :g, :h,
        :i, :j, :k, :l, :m, :n, :o, :p, :q, :r, 
        :s, :t, :u, :v, :w, :x, :y, :z,
      ].include?(symbol)
    end

    def initialize
      @shift = false
      @control = false
      @super = false
      @alt = false

      @keys = {}
      @pressed = []
      @released = []

      # populate the key states
      KEY_CODES.each do |symbol, code|
        @keys[symbol] = { code: code, symbol: symbol, up: false, down: false, pressed: false, released: false }
      end
    end

    def symbol
      pressed[0]&.[](:symbol)
    end

    def code
      pressed[0]&.[](:code)
    end

    def char
      pressed[0]&.[](:char)
    end

    def ctrl
      @control
    end

    def reset
      @pressed.clear
      @released.clear
      
      @shift = false
      @control = false
      @super = false
      @alt = false
    end


    def key_is_letter?(symbol)
      symbol == :a || symbol == :b || symbol == :c || symbol == :d ||
      symbol == :e || symbol == :f || symbol == :g || symbol == :h ||
      symbol == :i || symbol == :j || symbol == :k || symbol == :l ||
      symbol == :m || symbol == :n || symbol == :o || symbol == :p || 
      symbol == :q || symbol == :r || symbol == :s || symbol == :t ||
      symbol == :u || symbol == :v || symbol == :w || symbol == :x ||
      symbol == :y || symbol == :z
    end

    def char_code_from_key(key, shift)
      code = keys[key][:code]

      if !shift && key_is_letter?(key)
        code += 32 
      elsif shift && key == :apostrophe
        code = 34
      elsif shift && key == :comma
        code = 60
      elsif shift && key == :minus
        code = 95
      elsif shift && key == :period
        code = 62
      elsif shift && key == :slash
        code = 63
      elsif shift && key == :zero
        code = 41
      elsif shift && key == :one
        code = 33
      elsif shift && key == :two
        code = 64
      elsif shift && key == :three
        code = 35
      elsif shift && key == :four
        code = 36
      elsif shift && key == :five
        code = 37
      elsif shift && key == :six
        code = 94
      elsif shift && key == :seven
        code = 38
      elsif shift && key == :eight
        code = 42
      elsif shift && key == :nine
        code = 40
      elsif shift && key == :semicolon
        code = 58
      elsif shift && key == :equal
        code = 43
      elsif shift && key == :left_bracket
        code = 123
      elsif shift && key == :backslash
        code = 124
      elsif shift && key == :right_bracket
        code = 125
      elsif shift && key == :grave
        code = 126
      end

      return code if code <= 256
    end

    def set(key, down)
      if down
        case key
        when :left_shift, :right_shift
          @shift = true
        when :left_control, :right_control
          @control = true
        when :left_super, :right_super
          @super = true
        when :left_alt, :right_alt
          @alt = true
        end
      end

      if down && keys[key][:up]
        keys[key][:pressed] = true
        keys[key][:released]= false

        nkey = keys[key].dup
        nkey.merge!({ char: char_code_from_key(key, shift)&.chr })
        
        pressed << nkey
      elsif !down && keys[key][:down]
        keys[key][:pressed] = false
        keys[key][:released] = true

        nkey = keys[key].dup
        nkey.merge!({ char: char_code_from_key(key, shift)&.chr })

        released << nkey
      else
        keys[key][:pressed] = false
        keys[key][:released] = false
      end

      keys[key][:down] = down
      keys[key][:up] = !down
    end
  end
end
