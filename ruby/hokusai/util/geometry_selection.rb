module Hokusai::Util
  class GeometrySelection
    attr_accessor :start_x, :start_y, :stop_x, :stop_y,
                  :type, :cursor, :diff, :click_pos, :parent

    def initialize(parent)
      @parent = parent
      @type = :none         # state for the geometry selection (active/frozen/etc)
      @start_x = 0.0        # the x coordinate for the geometry
      @stary_y = 0.0        # the y coordinate for the geometry 
      @stop_x = 0.0
      @stop_y = 0.0
      @diff = 0.0
      @cursor = nil
      @click_pos = nil
    end

    def set_click_pos(x, y)
      @click_pos = [x, y]
    end

    def none?
      type == :none
    end

    def ready?
      type == :none || type == :frozen
    end

    def clear
      self.start_x = 0.0
      self.start_y = 0.0
      self.stop_x = 0.0
      self.stop_y = 0.0
      self.cursor = nil
    end

    def changed_direction?
      @changed_direction
    end

    def active?
      type == :active
    end

    def frozen?
      type == :frozen
    end

    def activate!
      self.type = :active
    end

    def freeze!
      self.type = :frozen
    end

    def coords
      [start_x, stop_x, start_y, stop_y]
    end

    def start(x, y)
      self.start_x = x
      self.start_y = y
      self.stop_x = x
      self.stop_y = y
      self.cursor = nil

      activate!
    end

    def stop(x, y)
      self.stop_x = x
      self.stop_y = y

      if up? && @direction == :down || down? && @direction == :up
        @changed_direction = true
      else
        @changed_direction = false
      end

      @direction = up? ? :up : :down
    end

    def up?(height = 0)
      stop_y < start_y - height
    end

    def down?(height = 0)
      start_y <= stop_y - height
    end

    def left?
      stop_x < start_x
    end

    def right?
      start_x <= stop_x
    end

    def cursor
      return nil unless @cursor

      return [@cursor[0], @cursor[1] - parent.offset_y, @cursor[2], @cursor[3]] if frozen?

      @cursor
    end

    def rect_selected(rect)
      selected(rect[0], rect[1], rect[2], rect[3])
    end

    def clicked(x,y,w,h)
      return false if click_pos.nil?

      pos = Hokusai::Rect.new(x, y, w, h)
      # pos.move_x_left
      pos.includes_x?(click_pos[0]) && pos.includes_y?(click_pos[1])
    end

    def selected(x, y, width, height)
      return false if none?

      if frozen?
        y -= parent.offset_y
      end

      sx = @start_x
      sy = @start_y
      ex = @stop_x
      ey = @stop_y

      down = sy <= ey
      up = ey < sy
      left = ex < sx
      right = sx <= ex

      rect = Hokusai::Rect.new(x, y, width, height)
      x_shifted_right = rect.move_x_right(1)
      y_shifted_up = rect.move_y_up(2)
      y_shifted_down = rect.move_y_down(2)
      end_y = y + height

      a = ((down &&
        # first line of multiline selection
        ((x_shifted_right > sx && end_y < ey && rect.includes_y?(sy)) ||
          # last line of multiline selection
          (x_shifted_right <= ex && y_shifted_up + height < ey && y > sy) ||
          # middle line (all selected)
          (y > sy && end_y < ey))) ||
        (up &&
          # first line of multiline selection
          ((x_shifted_right <= sx && y > ey && rect.includes_y?(sy)) ||
          # last line of multiline selection
            (x_shifted_right >= ex && y_shifted_down > ey && end_y < sy) ||
            # middle line (all selected)
            (y > ey && y + height < sy))) ||
        # single line selection
        ((rect.includes_y?(sy) && rect.includes_y?(ey)) &&
          ((left && x_shifted_right < sx && x_shifted_right > ex) || (right && x_shifted_right > sx && x_shifted_right < ex)))
      )

      a
    end
  end
end