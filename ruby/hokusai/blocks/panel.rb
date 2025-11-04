class Hokusai::Blocks::Panel < Hokusai::Block
  template <<~EOF
    [template]
      hblock {
        :background="background"
        @wheel="wheel_handle"
      }
        clipped { :auto="autoclip" :offset="offset" }
          dynamic { @size_updated="set_size" }
            slot
        [if="scroll_active"]
          scrollbar.scroller {
            @scroll="scroll_complete"
            :top="panel_top"
            :goto="scrollbar_goto"
            :width="scroll_width"
            :background="scroll_background"
            :control_color="scroll_color"
            :control_height="scroll_control_height"
          }
  EOF

  uses(
    clipped: Hokusai::Blocks::Clipped,
    dynamic: Hokusai::Blocks::Dynamic,
    hblock: Hokusai::Blocks::Hblock,
    scrollbar: Hokusai::Blocks::Scrollbar
  )

  computed :align, default: "top", convert: proc(&:to_s)
  computed :scroll_goto, default: nil
  computed :scroll_width, default: 14.0, convert: proc(&:to_f)
  computed :scroll_background, default: nil, convert: Hokusai::Color
  computed :scroll_color, default: nil, convert: Hokusai::Color
  computed :background, default: nil, convert: Hokusai::Color
  computed :autoclip, default: true

  provide :panel_offset, :offset
  provide :panel_content_height, :content_height
  provide :panel_height, :panel_height
  provide :panel_top, :panel_top

  inject :selection

  attr_accessor :top, :panel_height, :scroll_y, :scroll_percent,
                :scroll_goto_y, :clipped_offset, :clipped_content_height

  def initialize(**args)
    @top = nil
    @panel_height = 0.0
    @scroll_y = 0.0
    @scroll_percent = 0.0
    @scroll_goto_y = nil
    @clipped_offset = 0.0
    @clipped_content_height = 0.0

    super
  end

  def wheel_handle(event)
    return if clipped_content_height <= panel_height

    new_scroll_y = scroll_y + event.scroll * 20

    if y = top
      if new_scroll_y < y
        self.scroll_goto_y = y
      elsif new_scroll_y - top >= panel_height
        self.scroll_goto_y = panel_height if scroll_percent != 1.0
      else
        self.scroll_goto_y = new_scroll_y
      end
    end
  end

  def panel_top
    top || 0.0
  end

  def set_size(_, height)
    if panel_height != clipped_content_height || clipped_content_height.zero?
      self.clipped_content_height = height
      # self.scroll_goto_y = self.scroll_y unless scroll_y == top
    end
  end

  def offset
    ((panel_content_height * scroll_percent) - (panel_height * scroll_percent))
  end

  def content_height
    clipped_content_height
  end

  def panel_content_height
    clipped_content_height < panel_height ? panel_height : clipped_content_height
  end

  def scroll_active
    clipped_content_height > panel_height
  end

  def scroll_complete(y, percent:)
    self.scroll_y = y
    self.scroll_percent = percent
    self.scroll_goto_y = nil

    # todo handle selection

    emit("scroll", y, percent: percent)
  end

  def scrollbar_goto
    scroll_goto_y || scroll_goto
  end

  def scroll_control_height
    return 20.0 if panel_height <= 0.0

    val = (panel_height / panel_content_height) * panel_height
    val < 20.0 ? 20.0 : val
  end

  def render(canvas)
    self.top = canvas.y
    self.panel_height = canvas.height

    yield canvas
  end
end