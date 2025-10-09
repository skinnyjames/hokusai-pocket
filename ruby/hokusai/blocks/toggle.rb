class Hokusai::Blocks::Toggle < Hokusai::Block
  template <<-EOF
  [template]
    empty { @click="toggle" }
  EOF

  uses(empty: Hokusai::Blocks::Empty)

  computed :size, default: 30.0, convert: proc(&:to_f)
  computed :active_color, default: [137, 126, 186], convert: Hokusai::Color
  computed :inactive_color, default: [61, 57, 81], convert: Hokusai::Color
  computed :color, default: [215, 212, 226], convert: Hokusai::Color

  attr_accessor :toggled

  def toggle(_)
    self.toggled = !toggled

    emit("toggle", value: toggled)
  end

  def computed_color
    toggled ? active_color : inactive_color
  end

  def initialize(**args)
    @toggled = false

    super(**args)
  end

  def render(canvas)
    width = size * 2
    radius = size / 2

    start = toggled ? (canvas.x + width - radius) : canvas.x + radius

    draw do
      rect(canvas.x, canvas.y, width.to_f, size) do |command|
        command.color = computed_color
        command.round = size
        command.padding = Hokusai::Padding.convert(20)
      end

      circle(start, canvas.y + radius, radius) do |command|
        command.color = color
      end
    end

    canvas.width = size * 2
    canvas.height = size

    yield(canvas)
  end
end