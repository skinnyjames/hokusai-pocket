# Public: Measures it's children and emits the width and height
class Hokusai::Blocks::Dynamic < Hokusai::Block
  template <<~EOF
    [template]
      slot
  EOF

  computed :reverse, default: false
  computed :vertical, default: true

  def before_updated
    width, height = compute_size

    emit("size_updated", width, height)
  end

  def on_resize(_)
    compute_size
  end

  def on_mounted
    compute_size
  end

  def compute_size
    h = 0.0
    w = 0.0

    if vertical
      children.each do |block|
        h += block.node.meta.get_prop?(:height)&.to_f || 0.0
        w += block.node.meta.get_prop?(:width)&.to_f || 0.0
      end
    else
      h = children.map {|block| block.node.meta.get_prop?(:height)&.to_f || 0.0 }.max
    end

    if @last && h < @last.height
      h = @last.height
    end

    node.meta.set_prop(:height, h)

    [w, h]
  end

  def render(canvas)
    canvas.vertical = vertical
    canvas.reverse = (reverse == true || reverse == "true")
    @last = canvas

    yield canvas
  end
end