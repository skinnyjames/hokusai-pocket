module Hokusai::Util
  # Public:  A timer utility to test for passed time.
  #          Useful for debounce operations or animations
  #
  # Examples
  #
  #   timer = Hokusai::Util::Timer.new
  #   timer.elapsed(1.0) # false
  #   Hokusai.sleep(1.2)
  #   timer.elapsed(1.0) # true
  #   timer.reset
  #
  class Timer
    attr_accessor :start

    def initialize
      @start = Hokusai.monotonic
    end

    # Public: Check for elapsed time
    #
    # seconds - Number of seconds to check for (Integer)
    #
    # Returns boolean
    def elapsed(seconds)
      Hokusai.monotonic - @start > seconds
    end

    # Public: Reset the timer
    #
    # Returns nothing
    def reset
      @start = Hokusai.monotonic
    end
  end
end