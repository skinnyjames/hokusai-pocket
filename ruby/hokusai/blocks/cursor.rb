class Hokusai::Blocks::Cursor < Hokusai::Block
  template <<~EOF
    [template]
      virtual
  EOF

  DEFAULT_COLOR = [255,0,0,244]

  computed :x, default: 0.0
  computed :y, default: 0.0
  computed :show, default: false
  computed :speed, default: 0.5
  computed :cursor_width, default: 2.0
  computed :cursor_height, default: 0.0
  computed :color, default: DEFAULT_COLOR, convert: Hokusai::Color

  inject :selection

  def initialize(**args)
    @active = false
    @iteration = 0

    super(**args)
  end

  def before_updated
    frames = speed * 30

    @active = @iteration < frames

    if @iteration >= 30
      @iteration = 0
    else
      @iteration += 1
    end
  end

  def render(canvas)
    diff = selection&.diff || 0.0
    
    if show
      draw do
        if @active
          rect(x, y + diff, cursor_width, cursor_height) do |command|
            command.color = color
          end
        end
      end
    end

    yield canvas
  end
end