require_relative "./geometry_selection"
require_relative "./position_selection"

module Hokusai::Util
  class Selection
    attr_reader :geom, :pos
    attr_accessor :type, :offset_y, :diff, :cursor

    def initialize
      @geom = GeometrySelection.new(self)
      @pos = PositionSelection.new
      @type = :geom
      @offset_y = 0.0
      @diff = 0.0
      @cursor = nil
    end

    def clear
      pos.clear
      geom.clear
    end

    def cursor
      geom.cursor
    end

    def geom!
      pos.clear
      pos.cursor_index = nil

      self.type = :geom
    end

    def pos!
      geom.clear

      self.type = :pos
    end

    def geom?
      type == :geom
    end

    def pos?
      type == :pos
    end

    def left?
      geom? ? geom.left? : pos.left?
    end

    def right?
      geom? ? geom.right? : pos.right?
    end

    def up?
      geom? && geom.up?
    end

    def down?
      geom? && geom.down?
    end

    def selecting?
      !(geom.type == :none && geom.click_pos.nil?)
    end

    # should we show the cursor?
    def active?
      !cursor.nil?
    end
  end
end