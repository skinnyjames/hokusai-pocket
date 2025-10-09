class Hokusai::Blocks::Variable < Hokusai::Block
  template <<~EOF
  [template]
    empty
  EOF

  uses(empty: Hokusai::Blocks::Empty)

  computed! :script

  def after_updated
    if @last_height != children[0].node.meta.get_prop(:height)
      @last_height = children[0].node.meta.get_prop(:height)

      node.meta.set_prop(:height, @last_height)
      emit("height_updated", @last_height)
    end
  end

  def on_mounted
    klass = eval(script)

    raise Hokusai::Error.new("Class #{klass} is not a Hokusai::Block") unless klass.ancestors.include?(Hokusai::Block)

    node.meta.set_child(0, klass.mount)
  end

  def render(canvas)
    if Hokusai.can_render(canvas)
      yield canvas
    end
  end
end