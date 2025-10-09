class Hokusai::Blocks::ScissorBegin < Hokusai::Block
  template <<~EOF
  [template]
    slot
  EOF

  computed :offset, default: 0.0, convert: proc(&:to_f)
  computed :auto, default: true

  def render(canvas)
    draw do
      scissor_begin(canvas.x, canvas.y, canvas.width, canvas.height)
    end

    canvas.y -= offset if auto
    canvas.offset_y = offset

    yield canvas
  end
end