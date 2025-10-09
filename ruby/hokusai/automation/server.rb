# frozen_string_literal: true

require "rack"
require "thin"
require "ostruct"
require_relative "./driver"
require_relative "./constants"

module Hokusai
  module Automation
    class App
      attr_reader :driver

      def self.queue
        @queue ||= {}
      end

      def initialize(driver)
        @driver = driver
      end

      ROUTES = [
        ["/commands/locate", DriverCommands::Locate],
        ["/commands/invoke", DriverCommands::Invoke],
        ["/commands/attribute", DriverCommands::GetAttribute],
        ["/commands/click", DriverCommands::TriggerMouseClick],
        ["/commands/drag", DriverCommands::TriggerMouseDrag],
        ["/commands/hover", DriverCommands::TriggerMouseHover],
        ["/commands/mousemove", DriverCommands::TriggerMouseMove],
        ["/commands/mousewheel", DriverCommands::TriggerMouseWheel],
        ["/commands/keyboard", DriverCommands::TriggerKeyboard]
      ].to_h

      def call(env)
        request = Rack::Request.new(env)

        unless request.post?
          return respond(404, "Not Found", {})
        end

        return respond(200, "") if request.path == "/ready"

        if command_klass = ROUTES[request.path]
          json = JSON.parse(request.body.string, symbolize_names: true)
          command = command_klass.new(json)
          driver.execute(command)

          Log.debug { "Pushed #{command.class} command #{driver.queue.commands}" }

          poll(command.request_id)
        else
          respond(403, "Bad Request", {})
        end
      end

      def poll(request_id)
        poll_timeout = 2
        poll_interval = 0.02
        start = Process.clock_gettime(Process::CLOCK_MONOTONIC)

        while (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start) < poll_timeout
          begin
            if payload = driver.results[request_id]
              driver.results.delete(request_id)

              _, value = payload

              Log.debug { "request id found! sending payload #{value}" }

              if value.is_a?(Automation::Error)
                message = value.message || "Something went wrong"

                return respond(500, "Error occurred: #{message}" , {"Content-Type" => "text/plain"})
              else
                return respond(200, {"value" => value}.to_json)
              end
            end

            sleep poll_interval
          rescue ex
            respond(500, "Error occurred while processing command: #{ex.message}", {"Content-Type" => "text/plain"})
          end
        end

        respond(408, "Timeout", {"Content-Type" => "text/plain"})
      end

      def parse_body(request)
        JSON.parse(request.body, symbolize_names: true) unless request.body.nil?
      end

      def respond(status, message, headers = {"Content-Type" => "application/json"})
        [status, headers, message]
      end
    end

    class Server
      def self.start(*args, driver: Hokusai::Automation::Driver.new)
        app = App.new(driver)

        @socket = Thin::Server.new(*args, app)
        
        Thread.new do
          @socket.start
        end
      end

      def self.stop
        @socket.stop
      end
    end
  end
end
