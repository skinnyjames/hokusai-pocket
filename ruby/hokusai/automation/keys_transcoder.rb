module Hokusai::Automation
  module KeysTranscoder
    KEYS = {
      shift: "\ue008",
      ctrl: "\ue009",
      alt: "\ue00A",
      super: "\ue03D",
      lshift: "\ue008",
      lctrl: "\ue009",
      lalt: "\ue00A",
      lsuper: "\ue03D",
      rshift: "\ue050",
      rctrl: "\ue051",
      ralt: "\ue052",
      rsuper: "\ue053",
      enter: "\ue007",
      tab: "\ue004",
      backspace: "\ue003",
      insert: "\ue016",
      delete: "\ue017",
      up: "\ue013",
      right: "\ue014",
      down: "\ue015",
      left: "\ue012",
      page_up: "\ue00E",
      page_down: "\ue00F",
      end: "\ue010",
      home: "\ue011",
      pause: "\ue00B",
      escape: "\ue00C",
      null: "\ue000",
      cancel: "\ue001",
      f1: "\ue031",
      f2: "\ue032",
      f3: "\ue033",
      f4: "\ue034",
      f5: "\ue035",
      f6: "\ue036",
      f7: "\ue037",
      f8: "\ue038",
      f9: "\ue039",
      f10: "\ue03A",
      f11: "\ue03B",
      f12: "\ue03C",
      kp0: "\ue01A",
      kp1: "\ue01B",
      kp2: "\ue01C",
      kp3: "\ue01D",
      kp4: "\ue01E",
      kp5: "\ue01F",
      kp6: "\ue020",
      kp7: "\ue021",
      kp8: "\ue022",
      kp9: "\ue023",
      multiply: "\ue024",
      add: "\ue025",
      separator: "\ue026",
      subtract: "\ue027",
      decimal: "\ue028",
      divide: "\ue029",
      equal: "\ue019",
      caps_lock: "\ue054",
      scroll_lock: "\ue055",
      num_lock: "\ue056",
      print_screen: "\ue057",
      kb_menu: "\ue058",
      back: "\ue059",
      menu: "\ue05A",
      volume_up: "\ue05B",
      volume_down: "\ue05C",
    }

    REVERSE_KEYS = KEYS.invert

    def self.[](key)
      return KEYS[key] if KEYS[key]

      raise Hokusai::Automation::Error.new("Unsupported key: #{key}")
    end

    def self.decode(str)
      parts = str.split("")
      keys = []
      prog = []

      while part = parts.shift

        if key = REVERSE_KEYS[part]
          if key == :null
            keys << prog
            prog = []
          else
            prog << key
          end
        else
          prog << part.to_s
        end
      end

      keys.concat prog
      keys
    end

    def self.encode(keys)
      keys.map { |key| encode_key(key) }.join("")
    end

    def self.encode_key(key)
      case key
      when Symbol
        self[key]
      when Array
        key = key.map do |e|
          if e.is_a?(Symbol)
            self[e]
          else
            e
          end
        end

        key << self[:null]
        key.join("")
      else
        key.to_s
      end
    end
  end
end