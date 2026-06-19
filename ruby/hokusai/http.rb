module Hokusai
  module HTTP
    class ResponseBody
      attr_reader :finished, :tmp
      attr_accessor :value, :buffer

      def initialize
        @buffer = ""
        @value = ""
        @tmp = "#{Hokusai.tmpdir}/#{Hokusai.monotonic}"
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
        @io ||= File.open(@tmp, "w")
        @io << content
      end

      def finish
        @finished = true
        @io.close
      end

      def json
        JSON.parse(all)
      end

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
