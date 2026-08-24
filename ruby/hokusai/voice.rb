module Hokusai
  class Voice
    def initialize
      @description = nil
      @actions = []
    end
  end

  module VoiceRegistration
    def register_voice(&block)
      @voice ||= Voice.new
      
      yield @voice
    end
  end
end