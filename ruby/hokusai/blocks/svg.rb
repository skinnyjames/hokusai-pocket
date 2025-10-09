class Hokusai::Blocks::SVG < Hokusai::Block
  template <<~EOF
    [template]
      virtual
  EOF

  computed! :source
  computed :size, default: 12, convert: proc(&:to_i)
  computed :color, default: [255,255,255], convert: Hokusai::Color

  def render(canvas)
    draw do
      svg(source, canvas.x, canvas.y, size, size) do |command|
        command.color = color
      end
    end

    yield canvas
  end
end