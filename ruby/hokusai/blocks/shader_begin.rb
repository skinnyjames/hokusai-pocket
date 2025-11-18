class Hokusai::Blocks::ShaderBegin < Hokusai::Block
  template <<~EOF
  [template]
    slot
  EOF

  computed :fragment_shader, default: nil
  computed :vertex_shader, default: nil
  computed :uniforms, default: {}
  computed :textures, default: {}

  def render(canvas)
    draw do
      shader_begin do |command|
        command.vertex_shader = vertex_shader
        command.fragment_shader = fragment_shader
        command.uniforms = uniforms
        command.textures = textures
      end
    end

    yield canvas
  end
end