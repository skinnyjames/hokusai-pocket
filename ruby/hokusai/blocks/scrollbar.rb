class Hokusai::Blocks::Scrollbar < Hokusai::Block
  style <<~EOF
  [style]
  scrollbar {
    cursor: "pointer";
  }
  EOF
  template <<~EOF
    [template]
      vblock.scrollbar {
        ...scrollbar
        @mousedown="scroll_start"
        @mousemove="scroll_handle"
        :background="background"
      }
        rect.top {
          :height="scroll_top_height"
        }
          empty
        rect.control {
          :color="control_color"
          :height="control_height"
          :rounding="control_rounding"
          :outline="control_padding"
          outline_color="0,0,0,0"
        }
          empty
        rect.bottom
          empty
  EOF

  uses(
    vblock: Hokusai::Blocks::Vblock,
    rect: Hokusai::Blocks::Rect,
    empty: Hokusai::Blocks::Empty
  )

  computed :goto, default: nil
  computed :background, default: [22,22,22], convert: Hokusai::Color
  computed :control_color, default: [66,66,66], convert: Hokusai::Color
  computed :control_height, default: 20.0, convert: proc(&:to_f)
  computed :control_rounding, default: 0.75, convert: proc(&:to_f)
  computed :control_padding, default: 2.0, convert: proc(&:to_f)

  attr_accessor :scroll_y, :scrolling, :height, :offset

  def scroll_start(event)
    self.scrolling = true
    do_goto(event.pos.y)

    event.stop
  end

  def scroll_handle(event)
    if event.left.down && scrolling
      do_goto(event.pos.y)

      event.stop
    else
      self.scrolling = false
    end
  end

  def scroll_top_height
    start = scroll_y
    control_middle = (control_height / 2)

    if start <= offset + control_middle
      return 0.0
    elsif start >= offset + height - control_middle
      return height - control_height
    else
      return scroll_y - offset - control_middle
    end

    0.0
  end

  def after_updated
    do_goto(goto) unless goto.nil?
  end

  def percent_scrolled
    return 0 if scroll_top_height === 0

    scroll_top_height / (height - control_height)
  end

  def do_goto(value)
    self.scroll_y = value.to_f

    emit("scroll", scroll_y, percent: percent_scrolled)
  end

  def initialize(**args)
    @scroll_y = 0.0
    @scrolling = false
    @height = 0.0
    @offset = 0.0

    super
  end

  def render(canvas)
    self.offset = canvas.y
    self.height = canvas.height

    yield(canvas)
  end
end