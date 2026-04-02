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
    def add(listener, extra: {})
      listeners << [listener, extra]
    end

    # emits `event` with `**args`
    # to all subscribers
    # @see
    # @param [String] name the event name
    # @param [**args] the args to emit
    def notify(name, *args, **kwargs)
      listeners.each do |(listener, extra)|
        raise Hokusai::Error.new("No target `##{name}` on #{listener.class}") unless name.is_a?(Proc) || listener.respond_to?(name)

        # for built asts
        if name.is_a?(Proc)
          extra.each do |proxy, value|
            proxy.value = value
          end

          listener.instance_exec(*args, **kwargs, &name)
        else
          listener.send(name, *args, **kwargs)
        end
      end
    end
  end
end