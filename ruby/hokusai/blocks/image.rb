# require "pathname"

class Hokusai::Blocks::Image < Hokusai::Block
  template <<~EOF
    [template]
      virtual
  EOF

  computed! :name
  computed :width, default: nil
  computed :height, default: nil
  computed :padding, default: Hokusai::Padding.new(0.0, 0.0, 0.0, 0.0), convert: Hokusai::Padding

  def render(canvas)
    if image = Hokusai.images.get(name)
      draw do
        image(image, canvas.x + padding.left, canvas.y + padding.top, (width&.to_f || canvas.width) - padding.right, (height&.to_f || canvas.height) - padding.bottom)
      end
    end

    yield canvas
  end
end