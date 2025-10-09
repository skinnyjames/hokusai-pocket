require_relative "./text"

class Input < Hokusai::Block
  template <<~EOF
  [template]
    panel {
      @click="start_selection"
      @hover="update_selection"
      :autoclip="true"
  }
      text {
        :content="model"
        :size="size"
        :padding="padding"
        :selection_color="text_selection_color"
        :selection_color_to="text_selection_color_to"
        :animate_selection="animate_selection"
        @selected="handle_selection"
        @keypress="handle_keypress"
        @click="update_click_position"
      }
      cursor {
        height="0"
        :color="cursor_color"
        :x="cursor_x"
        :y="cursor_y"
        :cursor_height="cursor_height"
        :show="cursor_show"
      }
  EOF

  uses(
    panel: Hokusai::Blocks::Panel,
    cursor: Hokusai::Blocks::Cursor,
    selectable: Hokusai::Blocks::Selectable,
    text: Text,
  )

  computed! :model

  computed :text_color, default: [33,33,33], convert: Hokusai::Color
  computed :text_selection_color, default: [233,233,233], convert: Hokusai::Color
  computed :text_selection_color_to, default: [0, 33, 233], convert: Hokusai::Color
  computed :animate_selection, default: false
  computed :cursor_color, default: [244,22,22], convert: Hokusai::Color
  computed :growable, default: false
  computed :size, default: 34, convert: proc(&:to_i)
  computed :padding, default: Hokusai::Padding.new(20.0, 20.0, 20.0, 20.0), convert: Hokusai::Padding

  attr_reader :selection
  attr_accessor :content, :buffer, :positions

  provide :selection, :selection

  def initialize(**args)
    super

    @buffer = ""
    @cursor = nil
    @selection = Hokusai::Util::SelectionNew.new
  end

  def update_click_position(event)
    selection.geom!
    selection.geom.set_click_pos(event.pos.x, event.pos.y)
  end

  def update_height(value)
    # node.meta.set_prop(:height, value)

    # emit("height_updated", value)
  end

  def handle_selection(copy)
    # puts [copy.inspect]
    # return if copy.nil?

    # @cursor = copy.cursor
  end

  def increment_cursor(selecting)
    selection.pos!

    selection.pos.move :right, selecting
  end

  def decrement_cursor(selecting)
    selection.pos!

    selection.pos.move :left, selecting
  end

  def handle_keypress(event)
    range = (selection.pos.positions.first..selection.pos.positions.last)

    if event.printable? && !event.super && !event.ctrl
      if selection.pos.positions.size > 0
        model[range] = event.char
        selection.pos.positions = []
        selection.geom.clear
        selection.pos.cursor_index = range.begin + 1
        # increment_cursor(false)
      elsif selection.pos.cursor_index
        model.insert(selection.pos.cursor_index + 1, event.char)
        increment_cursor(false)
      end
    elsif event.symbol == :backspace
      if selection.pos.positions.size > 0

        model[range] = ""
        selection.pos.positions = []
        selection.geom.clear
        selection.pos.cursor_index = range.begin + 1

        decrement_cursor(false) if selection.pos.cursor_index >= model.size

      elsif selection.pos.cursor_index
        model[selection.pos.cursor_index] = ""
        decrement_cursor(false)
      end
    elsif event.symbol == :right && selection.pos.cursor_index < model.size - 1
      increment_cursor(event.shift)
    elsif event.symbol == :left
      decrement_cursor(event.shift)
    end

    # puts ["model", model, selection.pos.cursor_index].inspect
  end

  # selection methods
  def start_selection(event)
    if event.left.down && !selection.geom.active?
      selection.pos.cursor_index = nil
      selection.geom!

      selection.geom.clear
      selection.geom.start(event.pos.x, event.pos.y)
    end
  end

  def update_selection(event)
    return unless selection.geom.active?

    if event.left.up
      selection.geom.freeze!
    elsif event.left.down
      selection.geom.stop(event.pos.x, event.pos.y)
    end
  end

  def cursor_x
    cursor(0)
  end

  def cursor_y
    cursor(1)
  end

  def cursor_height
    cursor(3)
  end

  def cursor_show
    !selection.cursor.nil?
  end

  def cursor(index)
    return if selection.cursor.nil?
    
    selection.cursor[index]
  end
end
