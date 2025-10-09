# frozen_string_literal: true

class Hokusai::Commands
  class Base
    def self.on_draw(&block)
      @draw = block
    end

    def self.draw
      @draw
    end

    def draw
      raise Hokusai::Error.new("No draw callback made for #{self.class}") if self.class.draw.nil?

      self.class.draw.call(self.freeze)
    end

    def after_draw(canvas)
    end
  end
end