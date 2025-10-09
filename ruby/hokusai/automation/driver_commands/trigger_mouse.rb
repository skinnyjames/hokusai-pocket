module Hokusai::Automation
  module DriverCommands
    module MouseMethods
      def trigger_mouse(input, **args)
        args.each do |which, bool|
          input.mouse.left.send("#{which}=", bool)
        end
      end
    end

    class TriggerMouseBase < Base
      include MouseMethods

      attr_accessor :value
    
      def initialize(hash)
        @value = false

        super
      end

      def location
        state[:uuid]
      end

      def button
        state[:button]
      end

      def button_symbol
        {
          0 => :left,
          1 => :middle,
          2 => :right
        }[button]
      end

      def on_complete
        return value if done?

        return Automation::Error.new("Could not locate block")
      end
    end

    class TriggerMouseDown < TriggerMouseBase
      def execute(blocks, canvas, input)
        if matches_blocks(blocks)
          
          mouse_center(canvas, input)
          trigger_mouse(input, down: true)

          self.value = true
          
          done!
        end
      end
    end

    class TriggerMouseUp < TriggerMouseBase
      def execute(blocks, canvas, input)
        if matches_blocks(blocks)
          
          mouse_center(canvas, input)
          trigger_mouse(input, up: true)

          self.value = true
          
          done!
        end
      end
    end

    class TriggerMouseClick < TriggerMouseBase
      def execute(blocks, canvas, input)
        if matches_blocks(blocks)
          mouse_center(canvas, input)
          trigger_mouse(input, clicked: true)

          self.value = true
          
          done!
        end
      end
    end

    class TriggerMouseRelease < TriggerMouseBase
      def execute(blocks, canvas, input)
        if matches_blocks(blocks)
          
          mouse_center(canvas, input)
          trigger_mouse(input, released: true)

          self.value = true
          
          done!
        end
      end
    end

    class TriggerMouseHover < Base
      def location
        state[:uuid]
      end

      def on_complete
        return true if done?

        return Automation::Error.new("Could not locate block")
      end

      def execute(blocks, canvas, input)
        if matches_block(blocks[0])
          mouse_center(canvas, input)

          done!
        end
      end
    end

    class TriggerMouseMove < Base
      def x
        state[:x]
      end

      def y
        state[:y]
      end

      def on_complete
        return true
      end

      def execute(blocks, canvas, input)
        mouse_move(x, y, input) unless done?

        done!
      end
    end

    class TriggerMouseDrag < Base
      include MouseMethods

      attr_accessor :dragging, :cursory_y, :button

      def initialize(hash)
        @dragging = false
        @cursory_y = 0.0
        @button = 0

        super
      end

      def location
        state[:uuid]
      end

      def x
        state[:x]
      end

      def y
        state[:y]
      end

      def on_complete
        return false if dragging

        true
      end

      def execute(blocks, canvas, input)
        if matches_block(blocks[0])
          local_x = x || canvas.x + (canvas.width / 2.0)
          local_y = y || canvas.y + (canvas.height / 2.0)

          if cursor_y < local_y && dragging
            trigger_mouse(input, down: true)
            mouse_move(local_x, cursor_y, input)

            self.cursor_y += 2.0
          elsif !dragging
            trigger_mouse(input, clicked: true)

            self.dragging = true
          else
            self.dragging = false
            
            done!
          end
        end
      end
    end

    class TriggerMouseWheel < Base
      def location
        state[:uuid]
      end

      def scroll_amount
        state[:scroll_amount]
      end

      def on_complete
        return true if done?

        return Automation::Error.new("Could not locate block")
      end

      def execute(blocks, canvas, input)
        if matches_block(blocks[0])
          mouse_center(canvas, input)

          input.mouse.scroll = scroll_amount

          done!
        end
      end
    end
  end
end