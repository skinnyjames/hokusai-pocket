class Hokusai::Blocks::TextStream < Hokusai::Block
  template <<~EOF
  [template]
    empty {
      cursor="ibeam"
    }
  EOF

  uses(empty: Hokusai::Blocks::Empty)

  computed! :content
  computed :font, default: nil
  computed :size, default: 16, convert: proc(&:to_i)
  computed :color, default: Hokusai::Color.new(33, 33, 33), convert: Hokusai::Color
  computed :selection_color, default: Hokusai::Color.new(233,233,233), convert: Hokusai::Color
  computed :padding, default: Hokusai::Padding.new(5.0, 5.0, 5.0, 5.0), convert: Hokusai::Padding
  computed :cursor_offset, default: nil

  inject :selection
  inject :panel_top
  inject :panel_height
  inject :panel_offset

  attr_accessor :last_commands, :last_content, :last_coords, :last_height,
                :last_width, :last_selector, :last_panel_offset, :copying, :buffer

  attr_reader :stream

  def initialize(**args)
    @last_commands = []
    @last_coords = nil
    @last_height = 0.0
    @last_width = nil
    @last_selector = nil
    @last_content = nil
    @last_panel_offset = nil
    @last_canvas = nil
    @copying = false
    @reset = false
    @buffer = ""

    super
  end

  def after_updated
    @stream&.reset(last_width)
  end
  
  def render(canvas)
    w = canvas.width - padding.left - padding.right
    poff = panel_offset || 0.0 - panel_top || 0.0
    selection&.offset_y = poff

    # lfont = Hokusai.fonts.active_font_name
    # Hokusai.fonts.activate font unless font.nil?

    # if Hokusai.can_render(canvas)
      # if (last_content != content || 
      #     last_width != w || 
      #     panel_offset != last_panel_offset || 
      #     last_coords != selection&.coords || 
      #     copying || 
      #     last_selector != selection&.type)

        last_commands.clear
        self.last_panel_offset = panel_offset
        self.last_content = content
        self.last_width = w
        self.last_selector = selection&.type
        self.last_coords = selection&.coords

        @stream ||= WrapStream.new(w) do |string, extra|
          Hokusai.fonts.active.measure(string, size)
        end

        stream.origin_x = canvas.x + padding.left
        stream.origin_y = canvas.y + padding.top
        stream.offset_y = 0.0
        stream.reset(w)

        draw do
          stream.on_text_selection(selection, nil) do |wrapped|
            self.buffer << wrapped.buffer if copying
            rect(wrapped.x, wrapped.y, wrapped.width, wrapped.height) do |command|
              command.color = selection_color

              last_commands << command
            end
          end

          stream.on_text do |wrapped|
            text(wrapped.text, wrapped.x, wrapped.y) do |command|
              command.color = color
              command.size = size
              command.font = font

              last_commands << command
            end
          end

          stream.wrap(content, nil)
          stream.flush
          stream.y += size
        end

        self.last_height = stream.y - canvas.y + padding.top + padding.bottom
        emit("height_updated", last_height)
        node.meta.set_prop(:height, last_height)


      # else
      #   draw do
      #     queue.concat last_commands
      #   end
      # end

      # if copying
      #   Hokusai.copy(buffer)
      #   self.buffer = ""
      #   self.copying = false
      # end

      # node.portal&.meta&.set_prop(:height, last_height + padding.top + padding.bottom)

      yield canvas
    # end

    # Hokusai.fonts.activate lfont
  end
end