class Hokusai::Blocks::DropdownItem < Hokusai::Block
  style <<~EOF
  [style]
    container {
      cursor: "pointer";
    }
  EOF
  
  template <<~EOF
  [template]
    empty.container { ...container @click="set_emit" @mouseup="emit_item"}
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
      @emit_next = false
    end
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

module Hokusai::Blocks::DropMix
  def prevent(event)
    event.stop
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
  end

  def render(canvas)
    @height ||= canvas.height

    yield canvas
  end
end

class Hokusai::Blocks::Dropdown < Hokusai::Block
  style <<~EOF
  [style]
  dropText {
    color: rgb(222,222,222);
    content: "Choose your destiny";
    outline: outline(0.0, 0.0, 1.0, 0.0);
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
        center { :vertical="true" }
          text { ...dropText :size="size" :content="active_content" }
        icon { ...dropIcon :size="size" @click="open"}
      [if="opened"]
        panel.panel { 
          ...itemStyle 
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

  attr_accessor :buffer

  include Hokusai::Blocks::DropMix
end


class Hokusai::Blocks::Dropup < Hokusai::Block
  style <<~EOF
  [style]
  dropText {
    color: rgb(222,222,222);
    outline: outline(0.0, 0.0, 1.0, 0.0);
    outline_color: rgb(43, 43, 43);
  }

  dropIcon {
    width: 60.0;
    background: rgb(22,22,22);
    color: rgb(222,222,222);
    outline: outline(0.0, 0.0, 1.0, 1.0);
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
    height: 300.0;
    autoclip: true;
  }

  item {
    padding: padding(10.0, 5.0, 10.0, 20.0);
    outline: outline(1.0, 0.0, 0.0, 0.0);
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
    vblock { z="2" :height="total_height" @keypress="autocomplete" @click="prevent" @mousedown="prevent" @hover="prevent" @wheel="prevent" }
      [if="opened"]
        panel.panel {
          ...itemStyle 
          :background="background"
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
                :background="background"
                :color="color"
                @picked="set_active" 
                :index="index"
                :height="height" 
                :key="option_key(item, index)" 
                :option="item"
                :size="size"
              }
      hblock { ...dropContainer :height="height" }
        center { :vertical="true" :height="height" }
          text { :size="size" ...dropText :content="active_content" }
        icon { ...dropIcon :size="size" type="up" @click="open" }
      
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
  computed :background, default: [22,22,22], convert: Hokusai::Color
  computed :color, default: [222,222,222], convert: Hokusai::Color
  computed :size, default: 24, convert: proc(&:to_i)
  computed :panel_height, default: 300.0, convert: proc(&:to_f)

  attr_accessor :buffer

  include Hokusai::Blocks::DropMix

  def total_height
    opened ? panel_height + @height : @height
  end

  def render(canvas)
    @height = canvas.height

    if opened
      canvas.y -= panel_height
    end

    yield canvas
  end
end
