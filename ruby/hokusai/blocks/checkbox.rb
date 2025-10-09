class Hokusai::Blocks::Checkbox < Hokusai::Block
  template <<~EOF
    [template]
      rect#checkbox {
        @click="check"
        :width="size"
        :height="size"
        :color="color"
      }
        [if="checked"]
          circle { :radius="circle_size" :color="circle_color" }
  EOF

  uses(
    rect: Hokusai::Blocks::Rect,
    circle: Hokusai::Blocks::Circle,
    empty: Hokusai::Blocks::Empty
  )

  DEFAULT_COLOR = [184,201,219]
  DEFAULT_CIRCLE_COLOR = [44, 113, 183]

  computed :color, default: DEFAULT_COLOR, convert: Hokusai::Color
  computed :circle_color, default: DEFAULT_CIRCLE_COLOR, convert: Hokusai::Color
  computed :size, default: 25.0

  attr_accessor :checked

  def circle_size
    (size.to_f * 0.35)
  end

  def check(event)
    self.checked = !checked

    emit("check", checked)
  end

  def initialize(**args)
    @checked = false

    super(**args)
  end

  def render(canvas)
    canvas.width = size.to_f
    canvas.height = size.to_f

    yield canvas
  end
end
