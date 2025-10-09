require_relative "../util/selection"

module Hokusai::Blocks
  class Selectable < Hokusai::Block
    template <<~EOF
      [template]
        vblock {
          @click="start_selection"
          @hover="update_selection"
        }
          slot
          cursor {
            height="0"
            :color="cursor_color"
            :x="cursor_x"
            :y="cursor_y"
            :cursor_height="cursor_height"
            :show="cursor_show"
          }
    EOF

    uses(
      vblock: Hokusai::Blocks::Vblock,
      cursor: Hokusai::Blocks::Cursor
    )

    computed :cursor_color, default: [255,22,22], convert: Hokusai::Color

    provide :selection, :selection

    attr_reader :selection

    def initialize(**args)
      @selection = Hokusai::Util::Selection.new

      super
    end

    def start_selection(event)
      if event.left.down && !selection.active?
        selection.clear
        selection.start(event.pos.x, event.pos.y)
      end
    end

    def update_selection(event)
      return unless selection.active?
      
      if event.left.up
        selection.freeze!
      elsif event.left.down
        selection.stop(event.pos.x, event.pos.y)
      end
    end

    def cursor_x
      cursor(0)
    end

    def cursor_y
      cursor(1)
    end

    def cursor_height
      cursor(3)
    end

    def cursor_show
      !selection.cursor.nil?
    end

    def cursor(index)
      return if selection.cursor.nil?

      selection.cursor[index]
    end
  end
end