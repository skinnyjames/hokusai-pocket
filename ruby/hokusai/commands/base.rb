class Hokusai::Commands
  # Internal: Base Command used by Hokusai::Commands to generate an ordered list of commands
  #           for the C/Raylib backend
  class Base
    # Internal: set drawing callback
    # 
    # block - drawing callback proc
    # 
    # Returns nothing
    def self.on_draw(&block)
      @draw = block
    end

    # Internal: get drawing callback
    # 
    # Returns Proc
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