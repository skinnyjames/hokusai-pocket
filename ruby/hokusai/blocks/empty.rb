# Public: A block with a virtual node
#         useful for collecting events on a block without rendering anything
#         
# Examples
# 
#   template <<-EOF
#   [template]
#     empty { @click="do_something" }
#   EOF
#
class Hokusai::Blocks::Empty < Hokusai::Block
  template <<~EOF
    [template]
      virtual
  EOF

  def render(canvas)
    yield canvas
  end
end
