
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

  inject :panel_top
  inject :panel_offset
  computed :offset, default: 0.0, convert: proc(&:to_f)
  computed :auto, default: true

  def off
    panel_offset || offset
  end

  def render(canvas)
    draw do
      scissor_begin(canvas.x, canvas.y, canvas.width, canvas.height)
    end

    canvas.y -= off.dup if auto
    canvas.offset_y = off

    yield canvas
  end
end
