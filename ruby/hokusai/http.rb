module Hokusai
  module HTTP
  class ResponseBody
    attr_reader :finished
    attr_accessor :value, :buffer

    def initialize
      @buffer = ""
      @value = ""
      @tmp = "/tmp/#{Hokusai.monotonic}"
      @finished = false
    end

    def on_read(&block)
      io = File.open(@tmp, "r")
      io.each do |group|
        block.call(group)
      end

      io.close
    end
    
    def write(content)
      io = File.open(@tmp, "a")
      io << content
      io.close
    end

    def finish
      @finished = true
      @tmp.rewind
    end

    def json
      JSON.parse(@buffer)
    end

    def all
      File.read(@tmp)
    end
  end

  class Response
    attr_accessor :code, :status
    def initialize
      @code = nil
      @status = nil
      @body = ResponseBody.new
    end

    def body
      @body
    end
  end
end
end
