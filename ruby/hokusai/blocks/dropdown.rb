class Hokusai::Blocks::DropdownItem < Hokusai::Block
  style <<~EOF
  [style]
    container {
      cursor: "pointer";
    }
  EOF
  
  template <<~EOF
  [template]
    empty.container { ...container @mousedown="set_emit" @mouseup="emit_item"}
  EOF

  computed! :option
  computed :size, default: 24, convert: proc(&:to_i)
  computed :background, default: [22,22,22], convert: Hokusai::Color
  computed :outline, default: [1.0, 1.0, 1.0, 1.0], convert: Hokusai::Outline
  computed :outline_color, default: [55,55,55], convert: Hokusai::Color
  computed :color, default: [222,222,222], convert: Hokusai::Color
  computed :padding, default: [2.5, 5.0, 2.5, 5.0], convert: Hokusai::Padding
  computed :font, default: nil

  uses(
    empty: Hokusai::Blocks::Empty,
  )

  inject :panel_offset
  inject :panel_height
  inject :panel_top

  def set_emit(event)
    @emit_next = true
  end

  def content
    option.respond_to?(:value) ? option.value : option
  end

  def emit_item(event)
    if @emit_next
      emit("picked", option)
    end

    @emit_next = false
  end

  def update_height(height)
    node.meta.set_prop(:height, height)
    node.portal.meta.set_prop(:height, height)
  end

  def can_render(canvas)
    return true unless panel_offset && panel_height

    canvas.y + canvas.height > panel_top && canvas.y < panel_top + panel_height
  end

  def render(canvas)
    if can_render(canvas)
      draw do
        rect(canvas.x, canvas.y, canvas.width, canvas.height) do |command|
          command.color = background
          command.outline = outline
          command.outline_color = outline_color
          command.padding = padding
        end

        cy = canvas.y + (canvas.height / 2.0) - (size / 2)
        text(content, canvas.x + padding.left, cy) do |command|
          if font
            command.font = Hokusai.fonts.get(font)
          end
          command.size = size
          command.color = color
          command.padding = padding
        end
        
        yield canvas
      end
    end
  end
end
class Hokusai::Blocks::Dropdown < Hokusai::Block
  style <<~EOF
  [style]
  dropText {
    color: rgb(222,222,222);
    content: "Choose your destiny";
    outline: outline(0.0, 0.0, 1.0, 0.0);
    padding: padding(0.0, 0.0, 0.0, 20.0);
    outline_color: rgb(43, 43, 43);
  }

  dropIcon {
    width: 60.0;
    background: rgb(22,22,22);
    color: rgb(222,222,222);
    outline: outline(0.0, 1.0, 0.0, 1.0);
    outline_color: rgb(43, 43, 43);
    type: "down";
  }

  dropIcon@mousedown {
    color: rgb(22,22,22);
    background: rgb(222,88,88);
    cursor: "pointer";
  }

  itemStyle {
    z: 2;
    autoclip: true;
    background: rgb(22,22,22);
  }

  item {
    background: rgb(22,22,22);
    padding: padding(10.0, 5.0, 10.0, 20.0);
    outline: outline(0.0, 0.0, 1.0, 0.0);
    outline_color: rgb(44,44,44);
    color: rgb(222,222,222);
  }

  item@hover {
    background: rgb(222,88,88);
    color: rgb(22, 22, 22);
    cursor: "pointer";
  }
  
  dropContainer {
    background: rgb(22, 22, 22);
    outline: outline(1.0, 0.0, 1.0, 0.0);
    outline_color: rgb(43, 43, 43);
  }
  EOF

  template <<~EOF
  [template]
    vblock { @keypress="autocomplete" @click="prevent" @mousedown="prevent" @hover="prevent" @wheel="prevent" }
      hblock { ...dropContainer }
        text { ...dropText :padding="text_padding" :size="size" :content="active_content" }
        icon { ...dropIcon :size="size" @click="open"}
      [if="opened"]
        panel.panel {
          ...itemStyle 
          :zposition="zposition"
          :height="panel_height"
          @click="prevent"
          @wheel="prevent"
          @mousedown="prevent"
          @hover="prevent" 
          @mousemove="prevent" 
        }
          dynamic
            [for="item in filtered_options"]
              item { 
                ...item
                @picked="set_active" 
                :index="index"
                :height="height" 
                :key="option_key(item, index)" 
                :option="item" 
                :size="size"
              }
  EOF

  uses(
    center: Hokusai::Blocks::Center,
    vblock: Hokusai::Blocks::Vblock,
    hblock: Hokusai::Blocks::Hblock,
    text: Hokusai::Blocks::Text,
    icon: Hokusai::Blocks::Icon,
    item: Hokusai::Blocks::DropdownItem,
    panel: Hokusai::Blocks::Panel,
    dynamic: Hokusai::Blocks::Dynamic,
  )

  computed! :options
  computed :truncate, default: -1, convert: proc(&:to_i)
  computed :size, default: 24, convert: proc(&:to_i)
  computed :background, default: [22,22,22], convert: Hokusai::Color
  computed :color, default: [222,222,222], convert: Hokusai::Color
  computed :panel_height, default: 300.0, convert: proc(&:to_f)
  computed :direction, default: :down, convert: proc(&:to_sym)

  attr_accessor :buffer, :zposition

  def prevent(event)
    event.stop
  end

  def text_padding
    mheight = ((@height || 0.0) / 2.0)
    msize = (size / 2.0)
    top = mheight - msize
    Hokusai::Padding.new(top, 0.0, 0.0, 20.0)
  end

  def filtered_options
    if buffer.empty?
      options
    else
      options.select do |option|
        content(option).downcase.start_with?(buffer)
      end
    end
  end

  def autocomplete(key)
    if key.printable?
      @buffer << key.char
    elsif key.symbol == :backspace
      @buffer = @buffer[0..-2]
    end
  end
  
  def option_key(item, index)
    "#{content(item)}-#{index}"
  end

  def on_mounted
    @buffer = ""
  end

  attr_reader :opened, :height
  attr_accessor :active, :opened

  def open(event)
    self.opened = !opened
    @buffer = ""
  end

  def active_content
    self.active ||= options.first

    content(active)
  end

  def content(option)
    option.respond_to?(:value) ? option.value[0..truncate] : option[0..truncate]
  end

  def set_active(item)
    self.active = item
    self.opened = false
    emit("change", active)
  end

  def render(canvas)
    @height ||= canvas.height

    case direction
    when :down
      self.zposition = Hokusai::Boundary.new(0.0, 0.0, 0.0, 0.0)
    when :up
      self.zposition = Hokusai::Boundary.new(-(@height + panel_height), 0.0, 0.0, 0.0)
    else
    end

    yield canvas
  end
end