module Hokusai
  # Public: HTTP module used in [Hokusai::Block](/api/Hokusai/Block.html#fetch-url-opts-path-block)
  module HTTP
    # Public: Represents a response body from an HTTP Request.
    #         Each request writes to a tmpfile asynchronously, 
    #         the body retains an handle to this io.
    class ResponseBody
      @@seq = 0

      attr_reader :tmp, :io

      def initialize
        @@seq += 1
        @tmp = "#{Hokusai.tmpdir}/hokusai_#{@@seq}_#{Hokusai.monotonic}"
        @finished = false
        @io = nil
      end

      def write(content)
        @io ||= File.open(@tmp, "w")
        @io << content
      end

      def finish
        @finished = true
        @io ||= File.open(@tmp, "w")
        @io.close
      end

      # Public: Reads a buffered stream of (chunk_size) into (block)
      # 
      # chunk_size - bytes to read from the response io at a time
      # block - a callback called with the buffer until the io is read 
      #
      def on_read(chunk_size = 65536, &block)
        io = File.open(@tmp, "r")
        while (chunk = io.read(chunk_size))
          break if chunk.empty?
          block.call(chunk)
        end
      ensure
        io.close if io
        File.delete(@tmp) if File.exist?(@tmp)
      end

      # Public: Get this response body parsed as json
      def json
        JSON.parse(all)
      end
      
      # Public: Get this response body as a string
      def all
        io.read
      ensure
        io.close if io
        File.delete(@tmp) if File.exist?(@tmp)
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
