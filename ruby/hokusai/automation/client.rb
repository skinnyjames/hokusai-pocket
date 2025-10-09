require_relative "./constants"
require "json"
require "uri"
require "rest-client"

module Hokusai
  module Automation
    class Client
      class Block
        attr_reader :uuid, :client

        def self.locate(selector, client)
          value = client.make_request("commands/locate", { selector: selector })
          new(value, client)
        end

        def self.locate_all(selector, client)
          value = client.make_request("commands/locate", { selector: selector })

          value.map do |val|
            new(val, client)
          end
        end

        def initialize(uuid, client)
          @uuid = uuid
          @client = client
        end

        [[:left, 0], [:middle, 1], [:right, 2]].each do |(type, button)|
          define_method("#{type}_click") do
            client.make_request("commands/click", {uuid: uuid, button: button})
          end

          define_method("#{type}_mouseup") do
            client.make_request("commands/mouseup", {uuid: uuid, button: button})
          end
        end
    
        def click
          left_click
        end

        def mouseup
          left_mouseup
        end

        def prop(name)
          client.make_request("commands/attribute", { uuid: uuid, attribute_name: name})
        end

        def invoke(name)
          client.make_request("commands/invoke", {uuid: uuid, method: name})
        end

        def hover
          client.make_request("commands/hover", { uuid: uuid })
        end

        def drag_to(x, y)
          client.make_request("commands/drag", {uuid: uuid, x: x, y: y})
        end

        def send_keys(keys)
          case keys
          when String
            encoded = KeysTranscoder.encode(keys.chars)
          else
            encoded = KeysTranscoder.encode(keys)
          end

          client.make_request("commands/keyboard", {uuid: uuid, keys: encoded})
        end
    
        def scroll(to)
          client.make_request("commands/wheel", {id: uuid, scroll_amount: to})
        end
      end

      attr_reader :host, :port

      def self.start(host = "localhost", port=3000)
        new URI.parse("http://#{host}:#{port}")
      end

      def self.start_unix(path)
        new URI.parse("unix://#{path}")
      end

      def initialize(uri)
        @host = uri.host
        @port = uri.port
        @http = RestClient::Resource.new("#{uri.host}:#{uri.port}")

        wait_until_ready
      end

      def block(selector)
        block = Client::Block.locate(selector, self)
        if block_given?
          yield block
        else
          block
        end
      end

      def blocks(selector)
        Client::Block.locate_all(selector, self)
      end

      def make_request(command, json)
        begin
          res = @http[command].post(json.to_json, headers)

          if res.code == 200
            JSON.parse(res.body)["value"]
          else
            raise Automation::Error.new("Got status code #{res.code} - #{res.body}")
          end
        rescue StandardError => ex
          raise Automation::Error.new("Failed to make request: #{ex}")
        end
      end

      def wait_until_stopped(timeout: 2, interval: 0.2)
        time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        val = nil

        while (Process.clock_gettime(Process::CLOCK_MONOTONIC) - time) < timeout
          begin
            res = @http["ready"].post
            if res.code != 200
              break
            else
              sleep interval
            end
          rescue
            sleep interval
          end
        end
      end

      def wait_until_ready(timeout: 2, interval: 0.2)
        time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        val = nil

        while (Process.clock_gettime(Process::CLOCK_MONOTONIC) - time) < timeout
          begin
            @http.start
            res = @http["ready"].post
            if res.code == 200
              break
            else
              sleep interval
            end
          rescue
            sleep interval
          end
        end
      end

      def headers
        {"Content-Type" => "application/json" }
      end
    end
  end
end