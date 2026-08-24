module Hokusai
  # Public: Accessibilty api class
  class Voice
    def self.walk(block)
      stack = [block]
      while block = stack.pop
        if block.class.voice
          block.class.voice.ctx = block
        end

        stack.concat block.children
      end
    end

    def self.map
      @map ||= {}
    end

    def self.consume(str)
      # check for a prefixed command
      arr = @map.find do |prefix, voice|
        if prefix.is_a?(Regexp)
          re = prefix
        else
          re = Regexp.new("^#{prefix}", "i")
        end

        str.downcase =~ re
      end

      if arr
        res = arr[1].actions.each do |action|
          break true if action.test(arr[1].ctx, str.downcase)
        end
      else
        @map.each do |prefix, voice|
          voice.actions.each do |action|
            break true if action.test(voice.ctx, str.downcase)
          end
        end
      end
    end

    class Action
      attr_accessor :description_cb, :match_cb, :type, :keyword

      def initialize(type)
        @description_cb = ->() {}
        @match_cb = ->() {}
        if type.is_a?(String)
          @keyword = Regexp.new(type.downcase, "i")
        elsif type.is_a?(Regexp)
          @keyword = type
        end
      end

      def description(&block)
        @description_cb = block
      end

      def on_match(&block)
        @match_cb = block
      end

      def test(receiver, str)
        if str.match(@keyword)
          res = receiver.instance_exec(str, &@match_cb)

          Hokusai.speak(res) if res
          true
        else
          false
        end
      end
    end

    attr_accessor :description_cb, :actions, :name, :ctx

    def initialize(name)
      @name = name
      @description_cb = ->() {}
      @actions = []
      @ctx = nil
    end

    def description(&block)
      @description_cb = block
    end

    def build_action(name, &block)
      action = Action.new(name)
      block.call(action)
      @actions << action
    end
  end

  class Block
    def self.register_voice(prefix, &block)
      api = Voice.new(prefix)
      block.call(api)
      Voice.map[prefix] = api
      @voice = api
    end

    def self.voice
      @voice
    end
  end
end