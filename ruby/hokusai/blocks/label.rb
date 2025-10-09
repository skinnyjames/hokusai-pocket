# frozen_string_literal: true
class Hokusai::Blocks::Label < Hokusai::Block
  template <<~EOF
  [template]
    virtual
  EOF

  computed! :content
  computed :font, default: nil
  computed :size, default: 12
  computed :color, default: [33,33,33], convert: Hokusai::Color
  computed :padding, default: [5.0, 5.0, 5.0, 5.0], convert: Hokusai::Padding

  def initialize(**args)
    @content_width = 0.0
    @content_height = 0.0
    @updated = false
    @last_content = nil

    super(**args)
  end

  def render(canvas)
    if @last_content != content
      width, height = Hokusai.fonts.active.measure(content.to_s, size.to_i)
      node.meta.set_prop(:width, width + padding.right + padding.left)
      node.meta.set_prop(:height, height + padding.top + padding.bottom)
      emit("width_updated", width + padding.right + padding.left)

      @last_content = content
    end

    draw do
      text(content, canvas.x, canvas.y) do |command|
        command.color = color
        command.size = size
        command.padding = padding
        command.font = font unless font.nil?
      end
    end
  end
end
