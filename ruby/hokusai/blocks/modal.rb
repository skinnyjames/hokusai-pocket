class Hokusai::Blocks::Modal < Hokusai::Block
  style <<~EOF
  [style]
  closeButtonStyle {
    width: 40;
    height: 40;
    cursor: "pointer";
    padding: padding(10.0, 10.0, 10.0, 0.0)
  }
  EOF

  template <<~EOF
  [template]
    hblock
      empty
    hblock
      empty
      slot
      empty
    hblock
      empty
  EOF

  uses(
    vblock: Hokusai::Blocks::Vblock,
    hblock: Hokusai::Blocks::Hblock,
    empty: Hokusai::Blocks::Empty,
  )

  computed :active, default: false
  computed :background, default: [0, 0, 0, 200], convert: Hokusai::Color

  def emit_close(event)
    emit("close")
  end

  def on_mounted
    node.meta.set_prop(:z, 1)
    node.meta.set_prop(:ztarget, "root")
  end

  def render(canvas)
    return unless active

    draw do
      rect(canvas.x, canvas.y, canvas.width, canvas.height) do |command|
        command.color = background
      end
    end

    yield canvas
  end
end
