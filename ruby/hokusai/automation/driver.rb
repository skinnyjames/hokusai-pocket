require_relative "./driver_commands/base"
require_relative "./driver_commands/get_attribute"
require_relative "./driver_commands/invoke"
require_relative "./driver_commands/locate"
require_relative "./driver_commands/trigger_keyboard"
require_relative "./driver_commands/trigger_mouse"
require_relative "./driver_command_queue"

module Hokusai
  module Automation
    class Driver
      attr_reader :server, :queue, :results

      def initialize
        @queue = DriverCommandQueue.new
        @results = {}
        @server = Hokusai::Automation::Server
      end

      def serve(*args)
        @server.start(*args, driver: self)
      end

      def stop
        @server.stop
      end

      def complete
        queue.completed(results)
      end
      
      # Adds a driver command to the queue to be executed
      # 
      # Commands process one-by-one on each iteration of the
      # UI loop.  
      # 
      # When a command is finished, its result will be populated in `#results`
      def execute(command)
        queue.commands << command
      end

      # Process a command with the given UI state
      # 
      # Results will added to the results hash and picked up by the current server request
      # 
      # *  `blocks` is a tuple containing a block and its parent
      # *  `canvas` is the current canvas being painted
      # *  `input` is the application input state for this loop iteration
      def process(blocks, canvas, input)
        queue.process(blocks, canvas, input)
      end
    end
  end
end
