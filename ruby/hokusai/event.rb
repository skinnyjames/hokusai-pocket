module Hokusai
  # Internal: A UI input event used in [Hokusai::Painter](/api/Hokusai/Painter)
  class BaseEvent
    attr_reader :captures
    attr_accessor :stopped

    # Internal: Sets the name of this event kind
    #  
    # name - event name (String)
    # 
    def self.name(name)
      @name = name
    end

    def name
      self.class.instance_variable_get("@name")
    end

    # Internal: adds evented styles to this block
    # 
    # value - a Hokusai::Block 
    #
    def add_evented_styles(block)
      if target = block.node.meta.target
        block.node.add_evented_styles(target.class, name)
      end
    end

    # Internal: capture a block
    # 
    # value - a Hokusai::Block
    def add_capture(block)
      captures << block
    end

    # Internal: Has the event stopped propagation?
    # 
    # Returns boolean
    def stopped
      @stopped ||= false
    end

    # Public: Stop the event from bubbling
    # 
    # Returns nothing
    def stop
      self.stopped = true
    end

    # Internal: All captures for this event
    # 
    # Returns Array(Hokusai::Block)
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

    # Internal: Does the event match the provided Hokusai::Block template?
    #
    # value - a Hokusai::Block
    # 
    # Returns boolean
    def matches(block)
      return false if block.node.portal.nil?

      val = block.node.portal.ast.event(name)

      !!val
    end

    # Internal: Emit the event to all captured blocks,
    #           stopping if any of the blocks stop propagation
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