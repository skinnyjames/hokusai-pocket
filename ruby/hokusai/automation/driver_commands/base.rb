module Hokusai::Automation
  module DriverCommands
    class Base 
      attr_accessor :request_id, :status, :last_parent
      attr_reader :state

      [:waiting, :pending, :done].each do |key|
        define_method("#{key}?") do
          status == key
        end

        define_method("#{key}!") do
          self.status = key
        end
      end

      def initialize(hash)
        @state = hash
        @last_parent = nil
      end

      def status
        @status ||= :wait
      end

      def request_id
        @request_id ||= SecureRandom.uuid
      end

      def on_complete(&block)
        raise NotImplementedError.new("Must implement #{self.class}#on_complete")
      end

      def execute(blocks, canvas, input)
        raise NotImplementedError.new("Must implement #{self.class}#execute")
      end

      def matches_block(block)
        return false unless block.node.portal
        
        if location == block.node.portal.uuid.to_s
          
          return true
        end

        false
      end

      def matches_blocks(blocks)
        if matches_block(blocks[0]) || (last_parent == blocks[1] && !last_parent.nil?)
          self.last_parent = blocks[0]

          return true
        end

        false
      end


      def mouse_center(canvas, input)
        x = canvas.x + (canvas.width / 2)
        y = canvas.y + (canvas.height / 2)
  
        mouse_move(x, y, input)
      end

      def mouse_move(x, y, input)
        input.mouse.pos.x = x
        input.mouse.pos.y = y
      end
    end
  end
end