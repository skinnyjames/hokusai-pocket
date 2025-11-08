
require_relative './hokusai/error'
require_relative './hokusai/types'
require_relative './hokusai/node'
require_relative './hokusai/block'
require_relative './hokusai/commands'
require_relative './hokusai/font'
require_relative './hokusai/event'
require_relative './hokusai/painter'
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
require_relative './hokusai/blocks/svg'
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

require_relative './build_templates'

HP_SHADER_UNIFORM_FLOAT = 0      # Shader uniform type: float
HP_SHADER_UNIFORM_VEC2 = 1       # Shader uniform type: vec2 (2 float)
HP_SHADER_UNIFORM_VEC3 = 2       # Shader uniform type: vec3 (3 float)
HP_SHADER_UNIFORM_VEC4 = 3       # Shader uniform type: vec4 (4 float)
HP_SHADER_UNIFORM_INT = 4        # Shader uniform type: int
HP_SHADER_UNIFORM_IVEC2 = 5      # Shader uniform type: ivec2 (2 int)
HP_SHADER_UNIFORM_IVEC3 = 6      # Shader uniform type: ivec3 (3 int)
HP_SHADER_UNIFORM_IVEC4 = 7      # Shader uniform type: ivec4 (4 int)
HP_SHADER_UNIFORM_UINT = 8       # Shader uniform type: unsigned int
HP_SHADER_UNIFORM_UIVEC2 = 9     # Shader uniform type: uivec2 (2 unsigned int)
HP_SHADER_UNIFORM_UIVEC3 = 10    # Shader uniform type: uivec3 (3 unsigned int)
HP_SHADER_UNIFORM_UIVEC4 = 11    # Shader uniform type: uivec4 (4 unsigned int)

# A backend agnostic library for authoring 
# desktop applications
# @author skinnyjames
module Hokusai
  # Access the font registry
  #
  # @return [Hokusai::FontRegistry]
  def self.fonts
    @fonts ||= FontRegistry.new
  end

  # Close the current window
  #
  # @return [void]
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

  # Restores the current window
  #
  # @return [void]
  def self.restore_window
    @on_restore_window&.call
  end

  # Minimizes the current window
  #
  # @return [void]
  def self.minimize_window
    @on_minimize_window&.call
  end

  # **Backend** Provides the minimize window callback
  def self.on_minimize_window(&block)
    @on_minimize_window = block
  end

  # Maxmizes the current window
  #
  # @return [void]
  def self.maximize_window
    @on_maximize_window&.call
  end

  # **Backend** Provides the maximize window callback
  def self.on_maximize_window(&block)
    @on_maximize_window = block
  end

  # Sets the window position on the screen
  #
  # @param [Array<Float, Float>]
  # @return [void]
  def self.set_window_position(mouse)
    @on_set_window_position&.call(mouse)
  end

  # **Backend:** Provides the window position callback
  def self.on_set_window_position(&block)
    @on_set_window_position = block
  end

  # **Backend:** Provides the mouse position callback
  def self.on_set_mouse_position(&block)
    @on_set_mouse_position = block
  end

  # Sets the window position on the screen
  #
  # @param [Array<Float, Float>]
  # @return [void]
  def self.set_mouse_position(mouse)
    @on_set_mouse_position&.call(mouse)
  end

  def self.on_can_render(&block)
    @on_renderable = block
  end

  # Tells if a canvas is renderable
  # Useful for pruning unneeded renders
  #
  # @param [Hokusai::Canvas]
  # @return [Bool]
  def self.can_render(canvas)
    @on_renderable&.call(canvas)
  end

  def self.on_set_mouse_cursor(&block)
    @on_set_mouse_cursor = block
  end

  def self.set_mouse_cursor(type)
    @on_set_mouse_cursor&.call(type)
  end

  def self.on_copy(&block)
    @on_copy = block
  end

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

  def self.update(block)
    stack = [block]
    
    while block = stack.pop
      block.update

      stack.concat block.children.reverse
    end
  end
end
