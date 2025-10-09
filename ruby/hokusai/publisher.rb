module Hokusai
  # An event emitter
  class Publisher
    attr_reader :listeners

    def initialize(listeners = [])
      @listeners = listeners
    end

    # Adds a listener that subscribes
    # to events emitted
    # by this publisher
    #
    # @param [Hokusai::Block] listener
    def add(listener)
      listeners << listener
    end

    # emits `event` with `**args`
    # to all subscribers
    # @see
    # @param [String] name the event name
    # @param [**args] the args to emit
    def notify(name, *args, **kwargs)
      listeners.each do |listener|
        raise Hokusai::Error.new("No target `##{name}` on #{listener.class}") unless listener.respond_to?(name)

        listener.send(name, *args, **kwargs)
      end
    end
  end
end