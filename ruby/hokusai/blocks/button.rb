# frozen_string_literal: true

class Hokusai::Blocks::Button < Hokusai::Block
  template <<~EOF
    [template]
      rect {
        @click="emit_click"
        @hover="set_hovered"
        @mouseout="unset_hovered"
        :color="background_color"
        :height="button_height"
        :width="button_width"
        :rounding="rounding"
        :outline="outline"
        :outline_color="outline_color"
      }
        label {
          :padding="padding"
          :color="color"
          @width_updated="update_width"
          :content="content"
          :size="size"
        }
  EOF

  uses(label: Hokusai::Blocks::Label, rect: Hokusai::Blocks::Rect)

  DEFAULT_BACKGROUND = [39, 95, 206]
  DEFAULT_CLICKED_BACKGROUND = [24, 52, 109]
  DEFAULT_HOVERED_BACKGROUND = [242, 52, 109]

  computed :padding, default: [5.0, 15.0, 5.0, 15.0], convert: Hokusai::Padding
  computed :size, default: 24
  computed :rounding, default: 0.5
  computed :content, default: ""
  computed :outline, default: 0.0, convert: Hokusai::Outline
  computed :outline_color, default: nil, convert: Hokusai::Color
  computed :background, default: DEFAULT_BACKGROUND, convert: Hokusai::Color
  computed :hovered_background, default: DEFAULT_HOVERED_BACKGROUND, convert: Hokusai::Color
  computed :clicked_background, default: DEFAULT_CLICKED_BACKGROUND, convert: Hokusai::Color
  computed :color, default: [215, 213, 226], convert: Hokusai::Color

  attr_accessor :button_width

  def emit_click(event)
    @clicked = true

    event.stop

    emit("clicked", event)
  end

  def update_width(value)
    self.button_width = value + (outline.right)
  end

  def set_hovered(event)
    @hovered = true
    @clicked = event.left.down

    Hokusai.set_mouse_cursor(:pointer)
  end

  def unset_hovered(_)
    @clicked = false

    if @hovered
      Hokusai.set_mouse_cursor(:default)
    end

    @hovered = false
  end

  def button_height
    size + padding.top + padding.bottom
  end

  def after_updated
    node.meta.props[:height] = button_height
  end

  def background_color
    @hovered ? (@clicked ? clicked_background : hovered_background) : background
  end

  def render(canvas)
    canvas.height = button_height
    canvas.width = button_width

    yield canvas
  end

  def initialize(**args)
    @button_width = 0.0
    @hovered = false
    @clicked = false

    super
  end
end
