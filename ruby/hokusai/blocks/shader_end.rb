# Public: Stops a shader defined by ShaderBegin
class Hokusai::Blocks::ShaderEnd < Hokusai::Block
  template <<~EOF
  [template]
    virtual
  EOF

  def render(canvas)
    draw do
      shader_end
    end
  end
end
