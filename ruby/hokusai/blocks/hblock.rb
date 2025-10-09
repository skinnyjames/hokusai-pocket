class Hokusai::Blocks::Hblock < Hokusai::Block
  template <<~EOF
    [template]
      slot
  EOF

  computed :padding, default: 0, convert: Hokusai::Padding
  computed :background, default: nil, convert: Hokusai::Color
  computed :rounding, default: 0.0
  computed :outline, default: Hokusai::Outline.default, convert: Hokusai::Outline
  computed :outline_color, default: nil, convert: Hokusai::Color
  computed :reverse, default: false

  def render(canvas)
    canvas.vertical = false
    canvas.reverse = reverse

    if background.nil? && outline.nil?
      yield canvas
    else
      draw do
        rect(canvas.x, canvas.y, canvas.width, canvas.height) do |command|
          command.color = background if background
          command.outline = outline if outline
          command.outline_color = outline_color if outline_color
          command.round = rounding.to_f if rounding
          command.padding = padding
          canvas = command.trim_canvas(canvas)
        end
      end

      yield canvas
    end
  end
end