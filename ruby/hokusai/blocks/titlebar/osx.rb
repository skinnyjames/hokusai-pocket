module Hokusai::Blocks::Titlebar
  class OSX < Hokusai::Block
    GREEN = [38, 200, 75]
    YELLOW = [253, 189, 61]
    RED = [255, 92, 87]
    DEFAULT = [133, 133, 133]
    DRAG = [46,49,63]
    style <<~EOF
    [style]
    buttonStyle {
      cursor: "pointer";
    }
    EOF

    template <<-EOF
    [template]
      hblock {
        :background="get_background"
        :outline="outline"
        :outline_color="outline_color"
        :rounding="rounding"
        @mousedown="handle_move_start"
        @mousemove="handle_move"
        @hover="set_hover"
        @mouseout="clear_hover"
      }
        vblock { width="4" }
          empty
        vblock { width="60" }
          hblock 
            circle { ...buttonStyle @click="close" @hover="hover_red" @mouseout="blur_red" :radius="radius" :color="red" }
            circle { ...buttonStyle @click="minimize" @hover="hover_yellow" @mouseout="blur_yellow" :radius="radius" :color="yellow" }
            circle { ...buttonStyle @click="maximize" @hover="hover_green" @mouseout="blur_green" :radius="radius" :color="green" }
        vblock
          hblock
            slot
    EOF

    computed :rounding, default: 0.0, convert: proc(&:to_f)
    computed :outline, default: nil
    computed :outline_color, default: nil
    computed :unhovered_color, default: DEFAULT, convert: Hokusai::Color
    computed :radius, default: 6.0, convert: proc(&:to_f)
    computed :background, default: [22, 22, 22], convert: Hokusai::Color
    computed :background_drag, default: nil


    uses(
      circle: Hokusai::Blocks::Circle,
      vblock: Hokusai::Blocks::Vblock,
      hblock: Hokusai::Blocks::Hblock,
      empty: Hokusai::Blocks::Empty
    )

    attr_accessor :moving, :last_event, :hovering, :maximized

    def get_background
      moving ? background_drag : background
    end

    def handle_move_start(event)
      self.last_event = [event.pos.x, event.pos.y] unless moving
      self.moving = true
    end

    def handle_move(event)
      if moving && event.left.down
        x = event.pos.x - last_event[0]
        y = event.pos.y - last_event[1]

        Hokusai.set_window_position([x, y])
      else
        self.moving = false
      end
    end

    def set_hover(_)
      self.hovering = true
    end

    def clear_hover(_)
      self.hovering = false
    end

    def close(_)
      Hokusai.close_window
    end

    def minimize(_)
      Hokusai.minimize_window
    end

    def maximize(_)
      if maximized
        Hokusai.restore_window
        self.maximized = false
      else
        Hokusai.maximize_window
        self.maximized = true
      end
    end

    def blur_red(_)
      @hovered_red = false
    end

    def blur_yellow(_)
      @hovered_yellow = false
    end

    def blur_green(_)
      @hovered_green = false
    end

    def hover_red(_)
      @hovered_red = true
    end

    def hover_yellow(_)
      @hovered_yellow = true
    end

    def hover_green(_)
      @hovered_green = true
    end

    def red
      @hovered_red ? RED : unhovered_color
    end

    def yellow
      @hovered_yellow ? YELLOW : unhovered_color
    end

    def green
      @hovered_green ? GREEN : unhovered_color
    end

    def initialize(**args)
      super
      @hovered_red = false
      @hovered_yellow = false
      @hovered_green = false
      @moving = false
      @hovering = false
      @last_event = nil
      @maximized = false
    end
  end
end