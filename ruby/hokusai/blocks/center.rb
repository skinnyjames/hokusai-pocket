class Hokusai::Blocks::Center < Hokusai::Block
  template <<~EOF
  [template]
    dynamic { @size_updated="update_size" }
      slot
  EOF

  attr_accessor :cwidth, :cheight

  uses(dynamic: Hokusai::Blocks::Dynamic)

  computed :horizontal, default: false
  computed :vertical, default: false

  def update_size(width, height)
    self.cwidth = width
    self.cheight = height
  end

  def render(canvas)
    a = cwidth ? cwidth / 2 : 0.0
    b = cheight ? cheight / 2 : 0.0

    canvas.x = (canvas.x + canvas.width) / 2.0 - a if horizontal || (!horizontal && !vertical)
    canvas.y = canvas.y + (canvas.height / 2.0) - b if vertical || (!horizontal && !vertical)

    yield canvas
  end
end