module Hokusai::Automation
  module DriverCommands
    class TriggerKeyboard < Base
      attr_reader :exception

      def initialize(state)
        @exception = nil

        super
      end

      def location
        state[:uuid]
      end

      def keys
        @keys ||= KeysTranscoder.decode(state[:keys])
      end

      def on_complete
        if keys.empty?
          done!
        end

        return exception || true
      end

      def execute(blocks, canvas, input)
        return unless matches_block(blocks[0])

        Log.info { "Trigger keypress on #{blocks[0].class}" }

        decode_key = keys.shift

        mouse_center(canvas, input)
        input.mouse.left.clicked = true

        begin
          key_results = to_hml_keygroup(decode_key)

          input.keyboard.reset

          key_results.each do |key|
            Log.info { "populating #{key}"}

            input.keyboard.set(key, true)
          end
        rescue Automation::Error => ex
          keys.clear
          self.exeception = ex
          
          done!
        end
      end

      # Transforms a DecodedKey to an array of `LibHokusai::HmlInputKey`
      def to_hml_keygroup(decode_key)
        key_group = []

        case decode_key
        when Array
          decode_key.each do |key|
            if hml_key = CODE_TO_HML_KEY[key]
              key_group << hml_key
            else
              raise Automation::Exception.new("Error translating key to HmlInput: #{key} not found")
            end
          end
        else
          if hml_key CODE_TO_HML_KEY[decode_key]
            key_group << hml_key
          else
            raise Automation::Exception.new("Error translating key to HmlInput: #{key} not found")
          end
        end

        key_group
      end

      def to_hml_keys
        hml_keys = []

        keys.each do |decode_key|
          hml_keys << to_hml_keygroup(decode_key)
        end

        hml_keys
      end
    end
  end
end