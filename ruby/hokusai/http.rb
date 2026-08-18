module Hokusai
  # Public: HTTP module used in [Hokusai::Block](/api/Hokusai/Block.html#fetch-url-opts-path-block)
  module HTTP
    # Public: Represents http response
    class ResponseBody
      attr_reader :finished, :tmp
      attr_accessor :value, :buffer

      def initialize
        @buffer = ""
        @value = ""
        @tmp = "#{Hokusai.tmpdir}/#{Hokusai.monotonic}"
        @finished = false
      end

      # Public: buffered read callback to pipe response data
      # 
      # block - the callback
      # 
      # Returns nothing
      def on_read(&block)
        io = File.open(@tmp, "r")
        io.each do |group|
          block.call(group)
        end

        io.close
      end
      
      # Internal: Writes content to this response's io
      # 
      # content - a string
      def write(content)
        @io ||= File.open(@tmp, "w")
        @io << content
      end

      # Internal: closes the io
      def finish
        @finished = true
        @io.close
      end

      # Public: Get the response body as a ruby object
      # 
      # Returns Object
      def json
        JSON.parse(all)
      end

      # Public: Get response body as a String
      # 
      # Returns String
      def all
        tmp = File.read(@tmp)

        IO.popen("rm #{@tmp}") if File.exist?(@tmp)

        tmp
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
