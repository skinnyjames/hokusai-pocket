module Hokusai::Util
  # Public: Represents a selectable area with coordinates.
  #         Used from with [Util::Selection](/api/Hokusai/Util/Selection)
  #
  # Examples
  #
  #   geom = Hokusai::Util::GeometrySelection.new
  #   geom.start(0.0, 0.0)
  #   geom.stop(100.0, 100.0)
  #   geom.down? # true
  #   geom.selected(20.0, 20.0, 20.0, 20.0) # true
  #
  class GeometrySelection
    attr_reader :parent, :direction
    attr_accessor :start_x, :start_y, :stop_x, :stop_y, :click_pos, :modified, 
                  :changed_direction, :original_direction, :resized, :state
    
    def initialize(parent)
      @parent = parent
      @state = :none
      @start_x = 0.0
      @start_y = 0.0
      @stop_x = 0.0
      @stop_y = 0.0
      @click_pos = nil
      @modified = false
      @original_direction = nil
      @resized = false
    end

    # Public: Starts a selection
    #
    # x - the x coordinate selected (Float)
    # y - the y coordinate selected (Float)
    #
    # Returns nothing
    def start(x, y)
      self.start_x = x
      self.start_y = y + parent.offset_y
      self.stop_x = x
      self.stop_y = y + parent.offset_y
      self.click_pos = nil
      self.state = :selecting
      parent.cursor = nil
    end

    # Public: Moves the stop y coordinate up by (height)
    #
    # height - the amount to move up (Float)
    #
    # Returns nothing
    def move_up(height)
      self.stop_y -= height

      if (up? && @direction == :down) || (down? && @direction == :up)
        @changed_direction = true
      end

      @direction = up? ? :up : :down
    end


    # Public: Moves the stop y coordinate down by (height)
    #
    # height - the amount to move down (Float)
    #
    # Returns nothing
    def move_down(height)
      self.stop_y += height

      if (up? && @direction == :down) || (down? && @direction == :up)
        @changed_direction = true
      end

      @direction = up? ? :up : :down
    end

    # Public: Stops the selection
    #
    # x - the stop x coordinate (Float)
    # y - the stop y coordinate (Float)
    #
    # Returns nothing
    def stop(x, y)
      self.stop_x = x
      self.stop_y = y + parent.offset_y
      self.modified = true
      self.original_direction ||= up? ? :up : :down

      if (up? && @direction == :down) || (down? && @direction == :up)
        @changed_direction = true
      end

      @direction = up? ? :up : :down
    end

    def commit!
      parent.pos!
    end

    # Public: Is the selection going upward?
    #
    # Returns boolean
    def up?(height = 0)
      stop_y < start_y - height
    end

    # Public: Is the selection going downward?
    #
    # Returns boolean
    def down?(height = 0)
      start_y <= stop_y - height
    end

    # Public: Is the selection going left?
    #
    # Returns boolean
    def left?
      stop_x < start_x
    end

    # Public: Is the selection going right?
    #
    # Returns boolean
    def right?
      start_x <= stop_x
    end

    # Public: Did the selection change direction?
    #         (ie: selecting down but now going up)
    #
    # Returns boolean
    def changed_direction?
      @changed_direction
    end

    # Public: Resets the selection state
    #
    # Returns nothing
    def clear
      self.start_x = 0.0
      self.start_y = 0.0
      self.stop_x = 0.0
      self.stop_y = 0.0
      self.state = :none
      parent.cursor = nil
    end
    
    def rect_selected(rect)
      selected(rect[0], rect[1], rect[2], rect[3])
    end


    def clicked_on_line(x, y, w, h)
      return false if click_pos.nil?

      click_pos[0] > x + w && click_pos[1] > y - parent.offset_y && click_pos[1] <= y - parent.offset_y + h  && click_pos[0] > w
    end

    # Public: Is this region clicked?
    #         Note: need to set `click_pos` to use this.
    #
    # x - start x of the region (Float)
    # y - start y of the region (Float)
    # w - width of the region (Float)
    # h - height of the region (Float)
    #
    # Returns boolean
    def clicked(x,y,w,h)
      return false if click_pos.nil?

      pos = Hokusai::Rect.new(x, y - parent.offset_y, w, h)
      pos.includes_x?(click_pos[0]) && pos.includes_y?(click_pos[1])
    end

    # Public: Is this region selected?
    #
    # x - start x of the region (Float)
    # y - start y of the region (Float)
    # w - width of the region (Float)
    # h - height of the region (Float)
    #
    # Returns boolean
    def selected(x, ty, width, height)
      return false if parent.pos?

      y = ty - parent.offset_y
      sy = @start_y - parent.offset_y
      ey = @stop_y - parent.offset_y
      sx = @start_x
      ex = @stop_x

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