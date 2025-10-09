module Hokusai::Automation
  module DriverCommands
    class Invoke < Base
      attr_accessor :value

      def location
        state[:uuid]
      end

      def method
        state[:method]
      end

      def initialize(hash)
        @value = nil

        super
      end

      def on_complete
        return value if done?
      end

      def execute(block, canvas, input)
        return unless matches_block(blocks[0])

        self.value = blocks[0].send(method)

        done!
      end   
    end
  end
end
