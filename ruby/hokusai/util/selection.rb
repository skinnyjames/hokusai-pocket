require_relative "./geometry_selection"
require_relative "./position_selection"

module Hokusai::Util
  # Public: A utility to help coordinate selections.
  #         Currently used for text selection and in [Hokusai::Blocks::Selectable](/api/Hokusai/Blocks/Selectable)
  class Selection
    attr_reader :pos, :geom
    attr_accessor :offset_y, :offset_x, :offset_pos, :cursor, 
                  :action, :state, :use_focus, :focus_id, :top, :column,
                  :insert

    def initialize
      @pos = PositionSelection.new(self)
      @geom = GeometrySelection.new(self)
      @offset_y = 0.0
      @offset_x = 0.0
      @offset_pos = 0
      @cursor = nil
      @action = nil
      @state = :geom
      @use_focus = false
      @focus_id = nil
      @top = 0.0
      @column = nil
      @insert = false
    end

    # Public: Set the current cursor position
    #
    # arr - an array of 4 floats (start_x, stop_x, cursor_width, cursor_height)
    #
    # Returns nothing
    def cursor=(arr)
      return if (geom? && !geom.modified)

      @cursor = arr
    ensure
      geom.modified = false
    end

    # Public: Returns the selection y offset
    #
    # Returns a float
    def offset_y
      @top + @offset_y
    end

    def cursor
      return nil unless @cursor

      return [@cursor[0], @cursor[1] - offset_y, @cursor[2], @cursor[3]]
    end

    # Public: Is the selection in geometry mode?
    #
    # Returns boolean
    def geom?
      state == :geom
    end

    # Public: Use geometry mode
    #
    # clear - (boolean) should the positions be cleared? (default true)
    #
    # Returns nothing
    def geom!(pclear = true)
      pos.clear if pclear

      self.state = :geom
    end

    # Public: Is the selection in positional mode?
    #
    # Returns boolean
    def pos?
      state == :pos
    end

    # Public: Use positional mode
    #
    # clear - (boolean) should the geometry be cleared? (default false)
    #
    # Returns nothing
    def pos!(gclear = false)
      geom.clear if gclear
      geom.changed_direction = false
      geom.click_pos = nil

      self.state = :pos
    end

    # Public: Clear all selections and start in geometry mode.
    #
    # Returns nothing
    def clear
      geom.clear
      pos.clear
      self.cursor = nil

      geom!
    end

    # Public: Are we actively selecting?
    #
    # Returns boolean
    def selecting?
      (geom? && geom.state == :selecting) || (pos? && !pos.cursor_index.nil?)
    end
  end
end
