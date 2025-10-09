class Hokusai::Blocks::Texture < Hokusai::Block
  template <<~EOF
  [template]
    virtual
  EOF

  computed :width, default: nil, convert: proc(&:to_i)
  computed :height, default: nil, convert: proc(&:to_i)
  computed :x, default: nil
  computed :y, default: nil
  computed :rotation, default: nil
  computed :scale, default: 100.0
  
  def render(canvas)
    draw do
      texture(x || canvas.x, y || canvas.y, width || canvas.width, height || canvas.height) do |command|
        command.rotation = rotation if rotation
        command.scale = scale
      end
    end
  end
end
