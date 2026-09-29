require_relative "../util/selection"

# Public: slotted block which provides text selection information
#         to descendants
module Hokusai::Blocks
  class Selectable < Hokusai::Block
    template <<~EOF
      [template]
        dynamic {
          :vertical="vertical"
          @keypress="on_keypress"
          @keyup="on_keyup"
          @keydown="on_keydown"
          @hover="on_hover"
          @mouseup="on_mouseup"
          @click="on_click"
          @size_updated="update_height"
        }
          slot
          cursor {
            width="0"
            height="0"
            :color="cursor_color"
            :x="cursor_x"
            :y="cursor_y"
            :cursor_height="cursor_height"
            :show="cursor_show"
          }
    EOF

    uses(
      dynamic: Hokusai::Blocks::Dynamic,
      cursor: Hokusai::Blocks::Cursor
    )

    computed :cursor_color, default: [255,22,22], convert: Hokusai::Color
    computed :vertical, default: true
    computed :focus_mode, default: true
    computed :selection_override, default: nil

    provide :selection, :selection
    inject :panel_control

    attr_reader :timer
    attr_accessor :shift, :nav_target, :page_target

    def update_height(w, h)
      node.meta.set_prop(:height, h)
    end

    def initialize(**args)
      # our selection object
      @selection = Hokusai::Util::Selection.new
      # debounce timer for keydown
      @timer = Hokusai::Util::Timer.new
      @shift = false
      @nav_target = nil
      @page_target = nil
      @top = nil

      super
    end

    # we can override the selection object
    def selection
      selection_override || @selection
    end

    def on_keypress(event)
      self.shift = true if event.shift
      timer.reset

      if [:left, :right, :up, :down].include?(event.symbol)
        self.nav_target = event.symbol
      elsif [:home, :end, :page_up, :page_down].include?(event.symbol)
        self.page_target = true
      end
    end
    
    def on_keydown(event)  
      return unless timer.elapsed(0.2)
      selection.action = nav_target if nav_target 
      case nav_target
      when :left
        selection.pos.move(:left, true)
      when :right
        selection.pos.move(:right, true)
      when :up
        if selection.geom.stop_y - panel_control.offset < 70
          navheight = panel_control.scroll_y - 5
          panel_control.scroll_y = navheight
          panel_control.scroll_goto_y = navheight
          panel_control.scroll_percent = panel_control.local_percent_scrolled
        end
        selection.action = :up
      when :down
        if (panel_control.offset + panel_control.panel_height) - selection.geom.stop_y < 70
          navheight = panel_control.scroll_y + 5
          panel_control.scroll_y = navheight
          panel_control.scroll_goto_y = navheight
          panel_control.scroll_percent = panel_control.local_percent_scrolled
        end
        selection.action = :down
      end
    end

    def on_keyup(event)
      if nav_target && shift
        case nav_target
        when :left
          selection.pos.move(:left, true)
        when :right
          selection.pos.move(:right, true)
        when :up
          if selection.geom.stop_y - panel_control.offset < 70
            navheight = panel_control.scroll_y - 5
            panel_control.scroll_y = navheight
            panel_control.scroll_goto_y = navheight
            panel_control.scroll_percent = panel_control.local_percent_scrolled
          end
          selection.action = :up
        when :down
          if (panel_control.offset + panel_control.panel_height) - selection.geom.stop_y < 70
            navheight = panel_control.scroll_y + 5
            panel_control.scroll_y = navheight
            panel_control.scroll_goto_y = navheight
            panel_control.scroll_percent = panel_control.local_percent_scrolled
          end
          selection.action = :down
        end
      end

      if page_target && shift
        x = event.input.mouse.pos.x
        y = event.input.mouse.pos.y
        selection.geom.stop(x, y)
        selection.geom!
        selection.action = :collect
      end

      self.nav_target = nil
      self.page_target = nil
      self.shift = false unless event.shift
    end

    def on_resize(canvas)
      # resizing triggers a click event. >:(
      @resizing = true

      # ok, preserving the selection on resize is fine, but
      # the geometry is corrupted, so we have to clear it.
      # 
      # this makes shift + click fail intermittently after a resize.
      # work has been done, but the most stable thing to do is clear the selection.
      selection.clear
    end

    def on_click(event)
      if event.right.clicked
        p selection.inspect
        return
      end

      selection.action = { 2 => :word, 3 => :line, 4 => :all }[event.left.click_count]

      # if this is a fresh click
      # clear all selections
      if !shift && event.left.clicked && !@resizing
        selection.clear
        selection.geom.start(event.pos.x, event.pos.y)
        selection.geom.click_pos = [event.pos.x, event.pos.y]
      elsif shift && event.left.down && !@resizing
        selection.geom.stop(event.pos.x, event.pos.y)
        selection.geom!
        selection.action = :collect
      end
    end

    def on_mouseup(event)
      if event.left.released && !shift
        selection.column = nil
      end
    end

    def on_hover(event)
      return unless selection.geom?

      if event.left.up
        selection.action = nil
        # by the time we switch to pos, positions should already be populated.
        selection.pos!(false)
        selection.pos.freeze!
      elsif event.left.down && !event.input.keyboard.shift
        selection.geom.stop(event.pos.x, event.pos.y)
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

    def render(canvas)
      @top = canvas.y
      @resizing = false

      yield canvas
    end
  end
end
