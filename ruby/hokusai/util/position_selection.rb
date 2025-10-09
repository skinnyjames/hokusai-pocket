module Hokusai::Util
  class PositionSelection
    attr_accessor :positions, :cursor_index, :direction, :active

    def initialize
      @cursor_index = nil
      @positions = []
      @direction = :right
      @active = false
    end

    def move(to, selecting)
      self.active = selecting
  
      return if cursor_index.nil?

      # puts ["before", to, cursor_index, positions].inspect
      
      case to
      when :right
        self.cursor_index += 1
        if selecting && !positions.empty? && cursor_index <= positions.last
          positions.shift
        elsif selecting
          positions << cursor_index 
        end

      when :left
        if selecting && !positions.empty? && cursor_index >= positions.last
          positions.pop
        elsif selecting
          positions.unshift cursor_index
        end
  
        self.cursor_index -= 1 unless cursor_index == -1
      end
    end

    def active?
      @active
    end

    def left?
      direction == :left
    end

    def right?
      direction == :right
    end

    def clear
      self.cursor_index = nil
      positions.clear
    end

    def selected(index)
      active && (positions.first..positions.last).include?(index)
    end

    def select(range)
      self.positions = range.to_a
    end
  end
end