class Hokusai::Blocks::Texture < Hokusai::Block
  template <<~EOF
  [template]
    virtual
  EOF

  computed! :name
  computed :x, default: nil
  computed :y, default: nil
  computed :rotation, default: nil
  computed :scale, default: 1.0
  
  def render(canvas)
    draw do
      if tex = Hokusai.textures.get(name)
        texture(tex, x || canvas.x, y || canvas.y) do |command|
          command.rotation = rotation if rotation
          command.scale = scale
        end
      end
    end
  end
end
