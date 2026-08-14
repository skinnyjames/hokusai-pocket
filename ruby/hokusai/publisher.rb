module Hokusai
  # Internal: An event emitter
  class Publisher
    attr_reader :listeners

    def initialize(listeners = [])
      @listeners = listeners
    end

    # Internal: Adds a listener that subscribes to events emitted by this publisher
    #
    # listener - a Hokusai::Block
    def add(listener, extra: {})
      listeners << [listener, extra]
    end

    # Internal: emits `event` with `**args` to all subscribers
    #
    # name - event name
    # args - splatted arg array
    # kwargs - any kwargs to send
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