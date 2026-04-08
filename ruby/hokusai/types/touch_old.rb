# frozen_string_literal: true

module Hokusai
  class Touch
    attr_accessor :stack, :archive

    def initialize
      @stack = []
      @archive = []
      @tapped = false
      @swiped = false
      @pinched = false
      # @file = File.open("touch.log", "w")
    end

    def tapped?
      @tapped
    end

    def swiped?
      @swiped
    end

    def pinched?
      @pinched
    end

    def longtapping?
      log("#{touching?} - #{elapsed(token)}") if touching?
      touching? && elapsed(token) > 5
    end
    
    def longtapped?
      @longtapped
    end

    def touching?
      type == :down || type == :move
    end

    def duration
      if longtapping?
        return elapsed(token)
      end
      
      first, last = archive[-2..-1]

      last[:start] - first[:start]
    end

    def distance
      raise Hokusai::Error.new("Archive is empty") if archive.empty?
      first, last = archive[-2..-1]
      
      x = last[:x] - first[:x]
      y = last[:y] - first[:y]

      [x, y]
    end

    def direction
      raise Hokusai::Error.new("Archive is empty") if archive.empty?

      first, last = archive[-2..-1]
      
      x = last[:x] - first[:x]
      y = last[:y] - first[:y]

      if x.abs > y.abs
        # swiping left/right
        last[:x] > first[:x] ? :right : :left
      else
        # swiping up/down
        last[:y] > first[:y] ? :down : :up
      end
    end

    def angle
      raise Hokusai::Error.new("Archive is empty") if archive.empty?

      last, first = archive[-2..-1]
      
      x = last[:x] - first[:x]
      y = last[:y] - first[:y]

      (Math.atan2(x, y) * (-180 / Math::PI)).round(0).to_i
    end

    def log(str)
      # Thread.new do
      #   @file.write_nonblock("#{str}\n")
      # end
    end

    def record(finger, x, y)
      log("recording #{token}")
      if type == :down
        push(:move, finger, x, y)
        log("state is move")
      elsif type == :move
        stack.last[:x] = x
        stack.last[:y] = y
        
        log("updated state move")
      else 
        @longtapped = false
        @swiped = false
        @tapped = false
        push(:down, finger, x, y)
        log("state is down")
      end
    end

    def clear
      # log("clearing")
      if type == :move
        log("elapsed: #{elapsed(token)}")
        if elapsed(token) > 300 && within(10.0)
          @longtapped = true
          log('longtap')
        elsif within(10.0)
          @tapped = true
        else
          @swiped = true
          log('swipe')
        end
      elsif type == :down
        @tapped = true
        log('tap')
      else
        @longtapped = false
        @swiped = false
        @tapped = false
      end

      self.archive = stack.dup
      stack.clear
    end

    def elapsed(token)
      Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond) - token[:start]
    end

    def within(threshold)
      move = stack.last
      down = stack[-2]

      t1 = (move[:x] - down[:x]).abs
      t2 = (move[:y] - down[:y]).abs

      t1 < threshold && t2 < threshold
    end

    def pop
      stack.pop
    end

    def push(type, finger, x, y)
      log("push: #{type}")
      stack << {
        type: type,
        i: finger,
        x: x,
        y: y,
        start: Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond)
      }
    end

    def index
      token&.[](:finger)
    end

    def type
      token&.[](:type)
    end

    def token
      @stack.last
    end
  end
end