# require "pathname"

class Hokusai::Blocks::Image < Hokusai::Block
  template <<~EOF
    [template]
      virtual
  EOF

  computed! :source
  computed :width, default: nil
  computed :height, default: nil
  computed :padding, default: Hokusai::Padding.new(0.0, 0.0, 0.0, 0.0), convert: Hokusai::Padding

  def render(canvas)
    src = Pathname.new(source).absolute? ? source : "#{File.dirname(caller[-1].split(":")[0])}/#{source}"

    draw do
      image(src, canvas.x + padding.left, canvas.y + padding.top, (width&.to_f || canvas.width) - padding.right, (height&.to_f || canvas.height) - padding.bottom)
    end

    yield canvas
  end
end