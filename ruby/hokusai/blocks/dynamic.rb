class Hokusai::Blocks::Dynamic < Hokusai::Block
  template <<~EOF
    [template]
      slot
  EOF

  computed :reverse, default: false

  def before_updated
    width, height = compute_size

    emit("size_updated", width, height)
  end

  def on_mounted
    compute_size
  end

  def compute_size
    h = 0.0
    w = 0.0

    children.each do |block|
      h += block.node.meta.get_prop?(:height)&.to_f || 0.0
      w += block.node.meta.get_prop?(:width)&.to_f || 0.0
    end

    node.meta.set_prop(:height, h)

    [w, h]
  end

  def render(canvas)
    canvas.vertical = true
    canvas.reverse = (reverse == true || reverse == "true")

    yield canvas
  end
end