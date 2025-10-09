module Hokusai::Automation
  module DriverCommands
    class GetAttribute < Base      
      attr_accessor  :value

      def initialize(state)
        @value = nil

        super
      end

      def location
        state[:uuid]
      end

      def attribute_name
        state[:attribute_name]
      end

      def on_complete
        done!

        if value.nil?
          return ::Hokusai::Automation::Error.new("Attribute #{attribute_name} not found")
        end

        return value
      end

      def execute(blocks, canvas, input)
        return unless matches_block(blocks[0])

        Log.debug { "Props: #{blocks[0].node.meta.props}" }
        
        attribute = blocks[0].node.meta.props[attribute_name.to_sym]

        self.value = attribute
      end
    end
  end
end