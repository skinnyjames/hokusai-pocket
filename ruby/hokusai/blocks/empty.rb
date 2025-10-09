class Hokusai::Blocks::Empty < Hokusai::Block
  template <<~EOF
    [template]
      virtual
  EOF

  def render(canvas)
    yield canvas
  end
end
