# frozen_string_literal: true

module Hokusai
  # A Basic UI Event
  class Event
    attr_reader :captures
    attr_accessor :stopped

    # Sets the name of this event kind
    def self.name(name)
      @name = name
    end

    def name
      self.class.instance_variable_get("@name")
    end

    def add_evented_styles(block)
      if target = block.node.meta.target
        block.node.add_evented_styles(target.class, name)
      end
    end

    def add_capture(block)
      captures << block
    end

    # Has the event stopped propagation?
    # @return [Bool]
    def stopped
      @stopped ||= false
    end

    # Stop propagation on this event
    # @return [Void]
    def stop
      self.stopped = true
    end

    # @return [Array<Block>] the captured blocks for this event
    def captures
      @captures ||= []
    end

    # A JSON string representing this event
    # 
    # Used in automation
    # @return [String]
    def to_json
      raise Hokusai::Error.new("#{self.class} must implement to_json")
    end

    # Does the event match the provided Hokusai::Block?
    #
    # @param [Hokusai::Block]
    # @return [Bool]
    def matches(block)
      return false if block.node.portal.nil?

      val = block.node.portal.ast.event(name)

      !!val
    end

    # Emit the event to all captured blocks,
    # stopping if any of the blocks stop propagation
    def bubble
      while block = captures.pop
        block.emit(name, self)
        break if stopped
      end
    end
  end
end

require_relative './events/keyboard'
require_relative './events/mouse'
require_relative './events/touch'