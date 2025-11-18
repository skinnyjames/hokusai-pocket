class Hokusai::Blocks::Texture < Hokusai::Block
  template <<~EOF
  [template]
    virtual
  EOF

  computed :value, default: nil
  computed :x, default: nil
  computed :y, default: nil
  computed :flip, default: true
  
  def render(canvas)
    if tex = value
      draw do
        texture(tex, x || canvas.x, y || canvas.y) do |command|
          command.width = canvas.width
          command.height = canvas.height
          command.flip = flip
        end
      end
    end
  end
end
