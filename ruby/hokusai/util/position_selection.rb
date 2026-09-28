module Hokusai::Util
  # Public: Represents a selectable area using offsets. Designed for text/char selection.
  #         Used from with [Util::Selection](/api/Hokusai/Util/Selection)
  #         Depends on Util::GeometrySelection and also [Hokusai::Util::Wrapped](/api/Hokusai/Util/Wrapped)
  #
  class PositionSelection
    attr_reader :parent

    # Public: get/set the cursor offset
    #
    # index - an integer representing the current offset
    #
    # Returns the cursor ofset
    attr_accessor :cursor_index

    # Public: get/set the selected positions
    #
    # range - a range denoting the start..end selection
    #
    # Returns the positions
    attr_accessor :positions

    attr_accessor :state, :offset, :direction

    def initialize(parent)
      @parent = parent
      @positions = nil
      @cursor_index = nil
      @state = :none
      @offset = 0
      @direction = nil
    end

    # Public: Moves cursor to (index)
    #
    # to - the offset to move the cursor to
    # selecting - a boolean to denote that the move should adjust the selectable region
    #
    # Returns nothing
    def move(to, selecting, times = 1)
      return if cursor_index.nil? || (selecting && positions.nil?)

      case to
      when :right
        self.cursor_index += times

        if positions && cursor_index == positions.last
          self.positions = cursor_index..cursor_index
        elsif selecting && !positions.nil? && cursor_index <= positions.last
          self.positions = (positions.first + 1)...positions.last
        elsif selecting
          self.positions = positions.first..cursor_index 
        end

      when :left
        if selecting && !positions.nil? && cursor_index >= positions.last
          if positions.last - 1 < positions.first
            self.positions = positions.last - 1...positions.first
            @moved_left = true
          else
            self.positions = positions.first...positions.last - 1
          end
        elsif selecting
          self.positions = cursor_index...positions.last
        end
        self.cursor_index -= times unless cursor_index == -1

      end
    end

    def left?
      direction == :left
    end

    def right?
      direction == :right
    end

    # Public: Is this selection frozen?
    #
    # Returns boolean
    def frozen?
      state == :frozen
    end

    # Public: Freeze the selection to prevent modifications

    def freeze!
      self.state = :frozen
    end  

    # Public: merges the geometry selection into the existing positions
    #
    # arr - the tokens: _Array(Hokusai::Util::Wrapped)_ that are currently selected on the screen.
    #       Note: if the selection is out of the viewport, this will be missing tokens.
    #
    # Returns nothing
    def concat(arr)
      return if arr.nil?

      if @positions.nil?
        @positions = arr.first..arr.last

        return
      end

      if parent.geom.down? && parent.geom.changed_direction?
        max = [positions.first, arr.first].max
        if max == arr.last
          @positions = nil
          return
        end

        @positions = max..arr.last
        parent.geom.changed_direction = false # TEST: WIP
      elsif parent.geom.down?

        max = arr.last
        min = positions.first

        if min == max
          @positions = nil
          return
        end

        @positions = min..max
      elsif parent.geom.up? && parent.geom.changed_direction?
        min = [positions.first, arr.first].min
        max = [positions.first, arr.last].max

        if min == max
          @positions = nil
          return
        end

        if positions.first > arr.last
          max -= 1
        end

        @positions = min...max
        parent.geom.changed_direction = false #test WIP
      elsif parent.geom.up?
        if arr.first == positions.last || arr.first > positions.last
          @positions = nil
          return
        end

        min = []

        @positions = arr.first...positions.last
      else
        @positions = arr.first..arr.last
      end
    end

    # Public: Is this offset selected?
    #
    # offset - An index (Integer) to test
    #
    # Returns boolean
    def selected(index)
      return false if positions.nil?

      (positions.first..positions.last).include?(index)
    end

    # Public: Reset this selection
    #
    # Returns nothing
    def clear
      self.offset = 0
      self.cursor_index = nil
      self.positions = nil
      self.state = :none
    end
  end
end