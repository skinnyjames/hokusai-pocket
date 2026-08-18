# Public: Starts a clipping region with everything
#         inside being clipped to the canvas dimensions
#         Last child should be [Hokusai::Blocks::ScissorEnd](/api/Hokusai/Blocks/ScissorEnd)
#         
# Examples
# 
#   template <<-EOF
#   [template]
#     scissor_begin
#       more
#         components
#       scissor_end
#   EOF
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