
require_relative './hokusai/error'
require_relative './hokusai/types'
require_relative './hokusai/http'
require_relative './hokusai/ast'
require_relative './hokusai/node'
require_relative "./hokusai/node_builder"
require_relative './hokusai/block'
require_relative './hokusai/commands'
require_relative './hokusai/registry'
require_relative './hokusai/event'
require_relative './hokusai/painter'
require_relative './hokusai/texture_painter'
require_relative './hokusai/util/selection'
require_relative './hokusai/util/piece_table'
require_relative './hokusai/util/wrap_stream'
require_relative "./config"

require_relative './hokusai/blocks/empty'
require_relative './hokusai/blocks/vblock'
require_relative './hokusai/blocks/hblock'
require_relative './hokusai/blocks/label'
require_relative './hokusai/blocks/rect'
require_relative './hokusai/blocks/button'
require_relative './hokusai/blocks/circle'
require_relative './hokusai/blocks/checkbox'
require_relative './hokusai/blocks/scissor_begin'
require_relative './hokusai/blocks/scissor_end'
require_relative './hokusai/blocks/clipped'
require_relative './hokusai/blocks/cursor'
require_relative './hokusai/blocks/image'
require_relative './hokusai/blocks/toggle'
require_relative './hokusai/blocks/scrollbar'
require_relative './hokusai/blocks/dynamic'
require_relative './hokusai/blocks/panel'
require_relative './hokusai/blocks/text'
require_relative './hokusai/blocks/selectable'
require_relative './hokusai/blocks/input'
require_relative './hokusai/blocks/variable'
require_relative './hokusai/blocks/titlebar/osx'
require_relative './hokusai/blocks/modal'
require_relative './hokusai/blocks/texture'
require_relative './hokusai/blocks/shader_begin'
require_relative './hokusai/blocks/shader_end'
require_relative './hokusai/blocks/color_picker'
require_relative './hokusai/blocks/translation'
require_relative './hokusai/blocks/slider'
require_relative './hokusai/blocks/text'
require_relative './hokusai/blocks/center'
require_relative './hokusai/blocks/tooltip'
require_relative './hokusai/blocks/icon'
require_relative './hokusai/blocks/dropdown'

require_relative './patches'
require_relative './build_templates'

HP_SHADER_UNIFORM_FLOAT  = 0     # Shader uniform type: float
HP_SHADER_UNIFORM_VEC2   = 1     # Shader uniform type: vec2 (2 float)
HP_SHADER_UNIFORM_VEC3   = 2     # Shader uniform type: vec3 (3 float)
HP_SHADER_UNIFORM_VEC4   = 3     # Shader uniform type: vec4 (4 float)
HP_SHADER_UNIFORM_INT    = 4     # Shader uniform type: int
HP_SHADER_UNIFORM_IVEC2  = 5     # Shader uniform type: ivec2 (2 int)
HP_SHADER_UNIFORM_IVEC3  = 6     # Shader uniform type: ivec3 (3 int)
HP_SHADER_UNIFORM_IVEC4  = 7     # Shader uniform type: ivec4 (4 int)
HP_SHADER_UNIFORM_UINT   = 8     # Shader uniform type: unsigned int
HP_SHADER_UNIFORM_UIVEC2 = 9     # Shader uniform type: uivec2 (2 unsigned int)
HP_SHADER_UNIFORM_UIVEC3 = 10    # Shader uniform type: uivec3 (3 unsigned int)
HP_SHADER_UNIFORM_UIVEC4 = 11    # Shader uniform type: uivec4 (4 unsigned int)

# A backend agnostic library for authoring
# desktop applications
# @author skinnyjames
module Hokusai
  # Class for handling async work.
  class Work
    def initialize(receiver)
      @state = nil
      @receiver = receiver
      @on_execute_cb = nil
      @on_finished_cb = nil
    end

    def on_execute(state = nil, &block)
      @state = state
      @on_execute_cb = block
    end

    def on_finished(&block)
      @on_finished_cb = block
    end

    def execute(state)
      @on_execute_cb&.call(state)
    end

    def finish(receiver, value = nil)
      receiver.instance_exec(value, &@on_finished_cb)
    end
  end
  
  def self.http
    HTTP
  end

  def self.tmpdir
    @tmpdir || "."
  end

  def self.tmpdir=(val)
    @tmpdir = val
  end

  # Public: Access the font registry
  #
  # Returns a [Hokusai::FontRegistry](/api/Hokusai/FontRegistry)
  def self.fonts
    @fonts ||= FontRegistry.new
  end

  # Public: Access the texture registry
  # 
  # Returns a [Hokusai::TextureRegistry](/api/Hokusai/TextureRegistry)
  def self.textures
    @textures ||= TextureRegistry.new
  end

  # Public: Access the image registry
  # 
  # Returns a [Hokusai::ImageRegistry](/api/Hokusai/ImageRegistry)
  def self.images
    @images ||= ImageRegistry.new
  end

  # Public: Access the music registry
  # 
  # Returns a [Hokusai::MusicRegistry](/api/Hokusai/MusicRegistry)
  def self.musics
    @musics ||= MusicRegistry.new
  end

  # Public: close the current window
  #
  # Returns nothing
  def self.close_window
    @on_close_window&.call
  end

  # **Backend:** Provides the window close callback
  def self.on_close_window(&block)
    @on_close_window = block
  end

  # **Backend:** Provides the window restore callback
  def self.on_restore_window(&block)
    @on_restore_window = block
  end

  # Public: Restores the current window
  #
  # Returns nothing
  def self.restore_window
    @on_restore_window&.call
  end

  # Public: Minimizes the current window
  #
  # Returns nothing
  def self.minimize_window
    @on_minimize_window&.call
  end

  # **Backend** Provides the minimize window callback
  def self.on_minimize_window(&block)
    @on_minimize_window = block
  end

  # Public: Maxmizes the current window
  #
  # Returns nothing
  def self.maximize_window
    @on_maximize_window&.call
  end

  # **Backend** Provides the maximize window callback
  def self.on_maximize_window(&block)
    @on_maximize_window = block
  end

  def self.on_resize_window(&block)
    @on_resize_window = block
  end

  def self.resize_window(width, height)
    @on_resize_window&.call(width, height)
  end

  # Public: Sets the window position on the screen
  #
  # x - the screen's x coordinate
  # y - the screen's y coordinate
  #
  # Returns nothing
  def self.set_window_position(x, y)
    @on_set_window_position&.call(x, y)
  end

  # **Backend:** Provides the window position callback
  def self.on_set_window_position(&block)
    @on_set_window_position = block
  end

  # **Backend:** Provides the mouse position callback
  def self.on_set_mouse_position(&block)
    @on_set_mouse_position = block
  end

  # Public: Sets the mouse position
  # 
  # mouse - a Hokusai::Mouse with the position set.
  def self.set_mouse_position(mouse)
    @on_set_mouse_position&.call(mouse)
  end

  # **Backend** Provides the can_render callback
  def self.on_can_render(&block)
    @on_renderable = block
  end

  # **Backend** Provides the open_file callback
  def self.on_open_file(&block)
    @on_open_file = block
  end

  # Public: Picks a file path to open using native file dialog
  # 
  # hash - options for native file dialog
  #        :filter - A comma delimited string of extensions to filter
  #
  # Examples
  # 
  #   if path = Hokusai.open_file(filter: "png,jpg,jpeg,gif")
  #     p File.read(path)
  #   end
  #
  def self.open_file(hash = {})
    hash.transform_keys!(&:to_s)

    @on_open_file&.call(hash)
  end

  # **Backend** Provides the save_file callback
  def self.on_save_file(&block)
    @on_save_file = block
  end

  # Public: Picks a file path to save using native file dialog
  #
  # hash - options for native file dialog
  #        :filter - A comma delimited string of extensions to filter
  #
  # Examples
  #
  #   if path = Hokusai.save_file(filter: "txt,md")
  #     File.open(path, "w") { |io| io << "Hello" }
  #   end
  #
  # Returns nothing
  def self.save_file(hash = {})
    hash.transform_keys!(&:to_s)

    @on_save_file&.call(hash)
  end

  # Public: Tells if a canvas is renderable (useful for pruning unneeded renders)
  # 
  # canvas - a Hokusai::Canvas
  #
  # Returns a boolean
  def self.can_render(canvas)
    @on_renderable&.call(canvas)
  end

  # **Backend** Provides set mouse cursor callback
  def self.on_set_mouse_cursor(&block)
    @on_set_mouse_cursor = block
  end

  # Public: Sets the mouse cursor from the available types:
  # 
  # type - A symbol representing the type.
  #        can be one of [:default, :arrow, :ibeam, :crosshair, :pointer, :none]
  #
  def self.set_mouse_cursor(type)
    @on_set_mouse_cursor&.call(type)
  end

  # **Backend** Provides copy callback
  def self.on_copy(&block)
    @on_copy = block
  end

  # Public: Copies text to clipboard
  #
  # text - the text to copy (String)
  #
  # Returns nothing
  def self.copy(text)
    @on_copy&.call(text)
  end

  # Mobile support
  def self.on_show_keyboard(&block)
    @on_show_keyboard = block
  end

  def self.show_keyboard
    @on_show_keyboard&.call
  end

  def self.on_hide_keyboard(&block)
    @on_hide_keyboard = block
  end

  def self.hide_keyboard
    @on_hide_keyboard&.call
  end

  def self.on_keyboard_visible(&block)
    @on_keyboard_visible = block
  end

  def self.keyboard_visible?
    @on_keyboard_visible&.call
  end

  def self.on_speak_words
    @on_speak_words ||= []
  end

  def self.speak(words)
    on_speak_words << words
  end

  # Internal: Copies state from one Hokusai::Block to another Hokusai::Block
  #           Used in hot reloading to preserve state between reloads
  #           You probably don't need this
  def self.copy_state(src, target)
    stack = [src]
    tstack = [target]

    while src_block = stack.pop
      if t_block = tstack.pop
        if stack.size > tstack.size
          # nodes have been removed
          # drop nodes until they match up again.
          while src_block.class != t_block.class
            src_block = stack.pop
          end

        elsif tstack.size > stack.size
          # nodes have been added
          # skip until they match up again
          while src_block.class != t_block.class
            t_block = tstack.pop
          end
        end

        if t_block.class == src_block.class 
          src_block.instance_variables.each do |var|
            unless var == :@node
              t_block.instance_variable_set(var, src_block.instance_variable_get(var))
            end
          end

          src_block.node.meta.props.each do |k, v|
            t_block.node.meta.set_prop(k, v)
          end
        end

        tstack.concat t_block.children.reverse
      end

      stack.concat src_block.children.reverse
    end
  end

  # **Backend** updates the state in a Hokusai::Block 
  # after running event handlers
  def self.update(block)
    stack = [block]
  
    while block = stack.pop
      block.update
    
      stack.concat block.children.reverse
    end
  end
end
