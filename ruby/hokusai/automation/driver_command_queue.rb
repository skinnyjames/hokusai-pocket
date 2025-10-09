module Hokusai::Automation
  # A queue of `DriverCommand`
  # 
  # The queue is processed async on each iteration of the event loop
  class DriverCommandQueue
    attr_accessor :commands

    def initialize
      @commands = []
    end

    def completed(results)
      if command = commands[0]
        # command was added in the middle of a render cycle, don't complete it.
        return if command.waiting?

        if value = command.on_complete
          case value
          when ::Hokusai::Automation::Error
            results[command.request_id] = [command, value]
          else
            results[command.request_id] = [command, value]
          end
        end

        if command.done?
          
          commands.shift
        end
      end
    end

    # Processes any availabe commands in the queue
    # 
    # Returns a Tuple containing the command and it's wrapped return value
    def process(blocks, canvas, input)
      return nil if commands.empty?

      command = commands[0]

      # wait for the start of the render loop
      # 
      # if there is no parent, execute the command
      return if !blocks[1].nil? && command.waiting?

      command.pending! if command.waiting?
      command.execute(blocks, canvas, input)
    end
  end
end
