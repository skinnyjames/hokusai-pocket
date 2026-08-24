# Flags to pass to Hokusai::Backend::Config
# Example:
# ```ruby
# Hokusai::Backend.run(App) do |config|
#   config.config_flags = HP_FLAG_WINDOW_RESIZABLE | HP_FLAG_VSYNC_HINT
# end
# ```
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
  # A class for traversing a hokusai-pocket project
  # Yields every file that's required (depth-first)
  class Reloader
    def initialize(file_path, document = File.read(file_path))
      @file_path = file_path
      @document = document        
    end

    def traverse(&block)
      file_path_dir = File.dirname(@file_path)

      @document.gsub(/(?:require_relative\s+["'](.*)["'])/) do |path|
        base_path = Pathname.new(@file_path)
        path = Pathname.new("#{path.gsub(/require_relative\s+["']/, "").chop}.rb")
        resolved_path = Pathname.join(File.dirname(base_path.to_s), path).to_s

        block.call resolved_path

        Reloader.new(resolved_path).traverse(&block)
      end
    end
  end

  # Public: Runs a [Hokusai::Block](/api/Hokusai/Block) as a Game / Application
  #         Used by the C/MRuby/Raylb backend
  #
  # Examples
  #
  # Hokusai::Backend.run(BonziBuddy) do |config|
  #   config.title = "BonziBuddy reloaded"
  #   config.width = 500
  #   config.height = 500
  #   #
  #   # need to set at least one font if using text
  #   config.after_load do
  #     Hokusai.fonts.register "default", Hokusai::Backend::Font.default
  #     Hokusai.fonts.activate "default"
  #   end
  # end
  class Backend
    def self.htop  
      @running = true
      binding
    end

    # Public: Run a hokusai-pocket app.  Blocking until app is exited.
    #
    # klass - a Hokusai::Block.class
    # block - a callback to configure the application
    def self.run(klass, &block)
      return if @running
      config = Backend::Config.new
      block.call config

      obj = new(klass, config)
      obj.run
    end

    attr_reader :app, :config

    # Internal: constructor for Backend
    # 
    # app - a Hokusai::Block.class
    # config - a Hokusai::Backend::Config
    def initialize(app, config)
      @app = app
      @config = config
    end

    # Public: Configure the properties of a hokusai pocket app
    #         Set config flags, fps, title, and register assets.
    #         Passed as a callback parameter to [Hokusai::Backend.run](/api/Hokusai/Backend#run)
    class Config
      # Public: Set the width of the window on load
      #
      # value - The window pixel width (Integer)
      attr_accessor :width

      # Public: Set the height of the window on load
      #
      # value - The window pixel height (Integer)
      attr_accessor :height

      # Public: Set the desired frame rate (frames per second)
      #
      # value - The frames per second (Integer)
      attr_accessor :fps

      # Public: Set the title of the window
      #
      # value - The title of the window (String)
      attr_accessor :title

      # Public: Set any config flags for the window
      #
      # value - A union of HP_FLAG_*
      #
      # Examples
      #
      #   Hokusai::Backend.run(App) do |config|
      #     config.config_flags = HP_FLAG_VSYNC_HINT | HP_FLAG_WINDOW_RESIZABLE
      #   end
      #   # configures window to be resizable and sync frame rate with monitor
      attr_accessor :config_flags

      # Public: Set if application should pause rendering until an event comes through
      #
      # value - a boolean (false to turn off event waiting)
      attr_accessor :event_waiting

      # Public: Set if the application should draw the FPS in the top left corner
      #
      # value - true to draw FPS
      attr_accessor :draw_fps

      # Public: Set if the application should log to stdout
      #         Note LOG_LEVEL env var can be set to filter logging
      #
      # value - true to log
      attr_accessor :log

      # Public: Accessor to toggle audio (default false)
      #
      # value - true to use audio
      attr_accessor :audio

      # Public: Accessor to toggle touch input handling (default false)
      #
      # value - true to use touch events
      attr_accessor :touch

      attr_accessor :window_state_flags,
                  :automation_driver, :background, :after_load_cb,
                  :host, :port, :automated, :on_reload_proc, :voice

      def initialize
        @voice = false
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
        @on_reload_proc = nil
        @event_waiting = true
        @touch = false
        @log = false
      end

      # Internal: Not implemented
      def start_automation_driver
        raise ConfigError.new("Need a Hokusai::Driver in order to automate") if automation_driver.nil?

        automation_driver.serve(host, port)
      end

      # Internal: Not implemented
      def automate(host, port)
        self.host = host
        self.port = port
        self.automated = true
      end

      # Public: Called after the OpenGL context is established.
      # This is the place to register assets which depend on the GPU
      #
      # block - a callback to run code after an OpenGL window is established
      # 
      # Examples
      #
      #   Hokusai::Backend.run(App) do |config|
      #     config.after_load do
      #       Hokusai.fonts.register "default", Hokusai::Backend::Font.default
      #     end
      #   end
      # 
      # Returns nothing.
      def after_load(&block)
        self.after_load_cb = block
      end

      # Public: Sets hot reload entypoint (should probably be same as the app entrypoint)
      #         Note: for best results, also set `event_waiting = false`
      #
      # entrypoint - the file path to watch
      #
      # Returns nothing.
      def hot_reload=(entrypoint)
        @mtimes = {}
        topper = entrypoint
  
        on_reload do
          reload = false

          mtime = File::Stat.new(topper).mtime
          if !@mtimes[topper]
            @mtimes[topper] = mtime
          elsif @mtimes[topper] < mtime
            reload = true
            eval RubyResolver.new(topper).code, Backend.htop
            @mtimes[topper] = mtime
          end

          Reloader.new(topper).traverse do |file|
            mtime = File::Stat.new(file).mtime
            if !@mtimes[file]
              @mtimes[file] = mtime
            elsif @mtimes[file] < mtime
              reload = true

              eval RubyResolver.new(file).code, Backend.htop
              @mtimes[file] = mtime
            end
          end

          reload
        end
      end

      # Internal: Used by hot_reload= to set the reload logic
      def on_reload(&block)
        @on_reload_proc = block
      end
    end
  end
end
