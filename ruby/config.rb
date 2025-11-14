HP_FLAG_VSYNC_HINT = 64                  # Set to try enabling V-Sync on GPU
HP_FLAG_FULLSCREEN_MODE = 2              # Set to run program in fullscreen
HP_FLAG_WINDOW_RESIZABLE = 4             # Set to allow resizable window
HP_FLAG_WINDOW_UNDECORATED = 8           # Set to disable window decoration (frame and buttons)
HP_FLAG_WINDOW_HIDDEN = 128              # Set to hide window
HP_FLAG_WINDOW_MINIMIZED = 512           # Set to minimize window (iconify)
HP_FLAG_WINDOW_MAXIMIZED = 1024          # Set to maximize window (expanded to monitor)
HP_FLAG_WINDOW_UNFOCUSED = 2048          # Set to window non focused
HP_FLAG_WINDOW_TOPMOST = 4096            # Set to window always on top
HP_FLAG_WINDOW_ALWAYS_RUN = 256          # Set to allow windows running while minimized
HP_FLAG_WINDOW_TRANSPARENT = 16          # Set to allow transparent framebuffer
HP_FLAG_WINDOW_HIGHDPI = 8192            # Set to support HighDPI
HP_FLAG_WINDOW_MOUSE_PASSTHROUGH = 16384 # Set to support mouse passthrough, only supported when FLAG_WINDOW_UNDECORATED
HP_FLAG_BORDERLESS_WINDOWED_MODE = 32768 # Set to run program in borderless windowed mode
HP_FLAG_MSAA_4X_HINT = 32                # Set to try enabling MSAA 4X
HP_FLAG_INTERLACED_HINT = 65536          # Set to try enabling interlaced video format (for V3D)

module Hokusai
  class Backend
    def self.run(klass, &block)
      config = Backend::Config.new
      block.call config
      app = klass.mount

      obj = new(app, config)
      obj.run
    end

    attr_reader :app, :config

    def initialize(app, config)
      @app = app
      @config = config
    end

    class Config
      attr_accessor :width, :height, :fps,
                  :title, :config_flags, :window_state_flags,
                  :automation_driver, :background, :after_load_cb,
                  :host, :port, :automated, :on_reload, :event_waiting, :touch,
                  :draw_fps, :log, :audio

      def initialize
        @width = 500
        @height = 500
        @fps = 60
        @audio = true
        @draw_fps = false
        @title = "(Unknown Title)"
        @config_flags = HP_FLAG_WINDOW_RESIZABLE | HP_FLAG_VSYNC_HINT
        @window_state_flags = HP_FLAG_WINDOW_RESIZABLE
        @automation_driver = nil
        @background = Hokusai::Color.new(255, 255, 255)
        @after_load_cb = nil
        @host = "127.0.0.1"
        @port = 4333
        @automated = false
        @on_reload = ->(_){}
        @event_waiting = false
        @touch = false
        @log = false
      end

      def start_automation_driver
        raise ConfigError.new("Need a Hokusai::Driver in order to automate") if automation_driver.nil?

        automation_driver.serve(host, port)
      end

      def automate(host, port)
        self.host = host
        self.port = port
        self.automated = true
      end

      def after_load(&block)
        self.after_load_cb = block
      end

      def on_reload(&block)
        @on_reload = block
      end
    end
  end
end
