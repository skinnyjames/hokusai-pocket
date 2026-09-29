# Renders block inside a scrollable panel (slotted)
class Hokusai::Blocks::Panel < Hokusai::Block
  template <<~EOF
    [template]
      hblock {
        :background="background"
        @wheel="wheel_handle"
        @click="drag_start"
        @mousemove="drag_update"
        @mouseup="drag_stop"
        @keypress="on_keypress"
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
  computed :scroll_wheel_speed, default: 10.0, convert: proc(&:to_f)
  computed :scroll_width, default: 14.0, convert: proc(&:to_f)
  computed :scroll_background, default: nil, convert: Hokusai::Color
  computed :scroll_color, default: nil, convert: Hokusai::Color
  computed :scroll_page_buffer, default: 2.0, convert: proc(&:to_f)
  computed :background, default: nil, convert: Hokusai::Color
  computed :autoclip, default: true
  computed :autoscroll, default: true

  provide :panel_offset, :display_offset
  provide :panel_content_height, :content_height
  provide :panel_height, :panel_height
  provide :panel_top, :panel_top
  provide :panel_control, :panel_control
  provide :panel_autoclip, :autoclip

  attr_accessor :top, :panel_height, :scroll_y, :scroll_percent,
                :scroll_goto_y, :clipped_offset, :clipped_content_height, :display_offset

  def initialize(**args)
    @top = nil
    @panel_height = 0.0
    @scroll_y = 0.0
    @scroll_percent = 0.0
    @scroll_goto_y = nil
    @clipped_offset = 0.0
    @clipped_content_height = 0.0
    @display_offset = 0.0
    
    super
  end

  def panel_control
    self
  end
  
  def on_keypress(event)
    return unless [:home, :end, :page_up, :page_down].include?(event.symbol)

    case event.symbol
    when :home
      self.scroll_y = 0.0
    when :end
      self.scroll_y = panel_height - scroll_control_height
    when :page_up
      if scroll_y > scroll_control_height
        self.scroll_y -= (scroll_control_height - scroll_page_buffer)
      else
        self.scroll_y = 0.0
      end
    when :page_down
      if scroll_y < panel_height
        
        self.scroll_y += (scroll_control_height - scroll_page_buffer)
      else
        self.scroll_y = panel_height
      end
    end

    self.scroll_goto_y = scroll_y
    self.scroll_percent = local_percent_scrolled
  end

  def drag_start(event)
    return unless autoscroll

    if event.left.down && !@dragging
      @dragging = true
    end
  end

  def drag_update(event)
    return unless autoscroll

    if @dragging && event.left.down && (event.pos.y < panel_top || event.pos.y > panel_top + panel_height)
      if event.pos.y < panel_top
        self.scroll_y -= scroll_wheel_speed
      else
        self.scroll_y += scroll_wheel_speed
      end
      self.scroll_goto_y = scroll_y
      self.scroll_percent = local_percent_scrolled
    end
  end

  def drag_stop(event)
    return unless autoscroll
    if event.left.up
      @dragging = false
    end
  end

  def on_resize(canvas)
    # transpose scroll_y to new position
    self.scroll_goto_y = panel_height * scroll_y / canvas.height
    self.top = canvas.y
    self.panel_height = canvas.height
  end

  def scroll_top_height
    start = scroll_y
    control_middle = (scroll_control_height / 2)

    if start <= panel_top 
      return 0.0
    elsif start <= panel_top + control_middle
      return scroll_y
    elsif start >= panel_top + panel_height
      return panel_height - scroll_control_height
    elsif start >= panel_top + panel_height - control_middle
      return panel_height
    else
      return scroll_y - panel_top
    end

    0.0
  end

  def local_percent_scrolled
    return 0.0 if scroll_top_height.zero?

    if scroll_top_height + scroll_control_height >= panel_height
      return 1.0
    end

    scroll_top_height / (panel_height - scroll_control_height)
  end

  def wheel_handle(event)
    @wheel = true

    return if clipped_content_height <= panel_height

    new_scroll_y = scroll_y + (event.scroll * (scroll_wheel_speed))

    if y = top
      # percent is 0.0
      if new_scroll_y < panel_top
        self.scroll_y = y
        self.scroll_percent = 0.0
        self.scroll_goto_y = y
      # percent is 1.0
      elsif event.scroll > 0.0 && new_scroll_y + scroll_control_height >= panel_top + panel_height
        self.scroll_y = panel_top + panel_height
        self.scroll_goto_y = panel_top + panel_height
        self.scroll_percent = 1.0
      elsif new_scroll_y >= panel_top + panel_height
        self.scroll_y = panel_top + panel_height
        self.scroll_goto_y = panel_top + panel_height
        self.scroll_percent = 1.0
      elsif event.scroll <= 0.0 && new_scroll_y > panel_top + panel_height - scroll_control_height && new_scroll_y > (panel_height / 2.0)
        self.scroll_goto_y = panel_top + panel_height - scroll_control_height
        self.scroll_y = panel_top + panel_height - scroll_control_height
        self.scroll_percent = local_percent_scrolled
      else
        self.scroll_goto_y = new_scroll_y 
        self.scroll_y = new_scroll_y
        self.scroll_percent = local_percent_scrolled
      end
    end
  end

  def panel_top
    top || 0.0
  end

  def set_size(_, height)
    if height < panel_height
      self.clipped_content_height = panel_height
    else
    # if panel_height != clipped_content_height || clipped_content_height.zero? || (height > clipped_content_height || height > 0)
      self.clipped_content_height = height
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

  def scroll_complete(y, percent:, manual:)
    if manual
      self.scroll_y = y
      self.scroll_percent = percent
    end

    self.scroll_goto_y = nil

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
    self.top ||= canvas.y
    self.panel_height = canvas.height

    target = offset
    self.display_offset += (target - display_offset) * 0.5

    yield canvas
  end
end
