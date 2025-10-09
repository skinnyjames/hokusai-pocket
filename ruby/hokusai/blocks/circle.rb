class Hokusai::Blocks::Circle < Hokusai::Block
  template <<~EOF
    [template]
      virtual
  EOF

  computed :radius, default: 10.0, convert: proc(&:to_f)
  computed :color, default: [255,255,255], convert: Hokusai::Color
  computed :outline, default: nil
  computed :outline_color, default: [0,0,0,0], convert: Hokusai::Color

  def render(canvas)
    x = canvas.x + (canvas.width / 2)
    y = canvas.y + canvas.height / 2

    draw do
      circle(x, y, radius) do |command|
        command.color = color
        if outline
          command.outline = outline
          command.outline_color = outline_color
        end
      end
    end

    yield canvas
  end
end
