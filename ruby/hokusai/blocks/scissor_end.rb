class Hokusai::Blocks::ScissorEnd < Hokusai::Block
  template <<~EOF
  [template]
    virtual
  EOF

  def render(canvas)
    draw do
      scissor_end
    end
  end
end
