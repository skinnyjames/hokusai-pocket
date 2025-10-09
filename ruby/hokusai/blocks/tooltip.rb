class Hokusai::Blocks::Tooltip < Hokusai::Block
  template <<~EOF
  [template]
    vblock
      vblock { @hover="set_active" @mouseout="unset_active"  @size_updated="update_size" }
        slot
      [if="active"]
        vblock { z="2" :zposition="zposition" :width="width" :height="height" :background="background" }
          text { :content="label" :size="size" :color="color" :padding="padding" }
  EOF

  computed! :label
  computed :direction, default: :down, convert: proc(&:to_sym)
  computed :size, default: 18, convert: proc(&:to_i);
  computed :padding, default: Hokusai::Padding.new(2.5, 15.0, 2.5, 15.0), convert: Hokusai::Padding
  computed :color, default: Hokusai::Color.new(22, 22, 22), convert: Hokusai::Color
  computed :background, default: Hokusai::Color.new(222,88,88), convert: Hokusai::Color

  uses(
    center: Hokusai::Blocks::Center,
    vblock: Hokusai::Blocks::Vblock,
    text: Hokusai::Blocks::Text,
    dynamic: Hokusai::Blocks::Dynamic
  )

  attr_accessor :active, :width, :height, :zposition

  def initialize(**args)
    @active = false
    @zposition = Hokusai::Boundary.default

    super
  end

  def after_updated
    if @width.nil?
      width, height = Hokusai.fonts.active.measure(label, size)
      @width = width + padding.width + 10.0
      @height = height + padding.height
    end
  end

  def set_active(_)
    self.active = true
  end

  def unset_active(_)
    self.active = false
  end

  def render(canvas)
    case direction
    when :down
      self.zposition = Hokusai::Boundary.new(10.0, 0.0, 0.0, (canvas.width  / 2.0) - (width / 2.0))
    when :right
      self.zposition = Hokusai::Boundary.new(-((canvas.height / 2.0) + (height / 2.0)), 0.0, 0.0, (canvas.width + 10.0))
    when :left
      self.zposition = Hokusai::Boundary.new(-(canvas.height / 2.0) + (height / 2.0), 0.0, 0.0, -(canvas.width + 10.0))
    when :up
      self.zposition = Hokusai::Boundary.new(10.0, 0.0, 0.0, (canvas.width  / 2.0) - (width / 2.0))
    end

    # if active
    #   draw do 
    #     rect(canvas.ox, canvas.oy, canvas.owidth, canvas.oheight) do |command|
    #       command.color = Hokusai::Color.new(0, 0, 0, 200)
    #     end
    #   end
    # end

    yield canvas
  end
end