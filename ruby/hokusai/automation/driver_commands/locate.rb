require_relative "../converters/selector_converter"

module Hokusai::Automation
  module DriverCommands
    class Locate < Base    
      attr_reader :matches

      def initialize(hash)
        @matches = []
        @selectors = nil

        super
      end

      def on_complete
        return if waiting?
        
        done!

        return ::Hokusai::Automation::Error.new("No matches found") if matches.empty?

        matches.last
      end

      def selectors
        @selectors ||= Converters::SelectorConverter.parse_selectors(state[:selector])
      end

      def execute(blocks, canvas, input)
        if selector = selectors.shift
          if selector.matches(blocks[0])
            Log.debug {"Location match! #{selector}" }

            portal = blocks[0].node.portal
            
            Log.debug { "uuid: #{portal.uuid.to_s}" }

            matches << portal.uuid.to_s

            selectors.unshift(selector) if selectors.empty?
          else
            selectors.unshift(selector)
          end
        end
      end      
    end
  end
end
