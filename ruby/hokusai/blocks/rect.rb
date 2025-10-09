class Hokusai::Blocks::Rect < Hokusai::Block
  template <<~EOF
    [template]
      slot
  EOF

  computed :color, default: nil, convert: Hokusai::Color
  computed :rounding, default: 0.0
  computed :outline, default: nil, convert: Hokusai::Outline
  computed :outline_color, default: nil, convert: Hokusai::Color

  def render(canvas)
    draw do
      rect(canvas.x, canvas.y, canvas.width, canvas.height) do |command|
        command.color = color unless color.nil?
        command.outline = outline unless outline.nil?
        command.outline_color = outline_color unless outline_color.nil?
        command.round = rounding
      end
    end

    yield canvas
  end
end