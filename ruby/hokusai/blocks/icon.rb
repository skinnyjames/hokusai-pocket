class Hokusai::Blocks::Icon < Hokusai::Block
  template <<~EOF
  [template]
    virtual
  EOF

  MAP = {
    foo: "\u{E057}",
    forward: "\u{E00B}",
    heart: "\u{E085}",
    camera: "\u{E03B}",
    download: "\u{E065}",
    sun: "\u{E000}",
    messages: "\u{E0B9}",
    clipboard: "\u{E04A}",
    plus: "\u{E0CE}",
    minus: "\u{E0BC}",
    down: "\u{E01D}",
    up: "\u{E01E}"
  }

  computed! :type
  computed :size, default: 15, convert: proc(&:to_i)
  computed :color, default: Hokusai::Color.new(0, 0, 0), convert: Hokusai::Color
  computed :background, default: Hokusai::Color.new(255, 255, 255, 0), convert: Hokusai::Color
  computed :outline, default: Hokusai::Outline.default, convert: Hokusai::Outline
  computed :outline_color, default: Hokusai::Color.new(0, 0, 0, 0), convert: Hokusai::Color
  computed :padding, default: Hokusai::Padding.new(2.5, 5.0, 2.5, 5.0), convert: Hokusai::Padding
  computed :center, default: true

  def get_icon_from_type
    MAP[type.to_sym]
  end

  def center_in(canvas, size)
    x = canvas.x + (canvas.width / 2.0) - ((size / 2) || 0.0)
    y = canvas.y + (canvas.height / 2.0) - ((size / 2) || 0.0)

    [x, y]
  end

  def render(canvas)
    if Hokusai.fonts.get("icons")
      draw do
        rect(canvas.x, canvas.y, canvas.width, canvas.height) do |command|
          command.color = background
          command.outline = outline
          command.outline_color = outline_color
        end

        x, y = center_in(canvas, size)

        text(get_icon_from_type, x, y) do |command|
          command.font = Hokusai.fonts.get("icons")
          command.size = size
          command.color = color
        end
      end

      yield canvas
    end
  end
end