class Hokusai::Blocks::Translation < Hokusai::Block
  template <<~EOF
  [template]
    dynamic { 
      @size_updated="set_size" 
    }
      slot
  EOF

  uses(dynamic: Hokusai::Blocks::Dynamic)

  attr_accessor :content_width, :content_height

  def set_size(width, height)
    self.content_width = width
    self.content_height = height
    node.meta.set_prop(:width, width)
    node.meta.set_prop(:height, height)
  end

  computed :duration, default: 500.0, convert: proc(&:to_f)
  computed :from, default: :top, convert: proc(&:to_sym)

  def circular_in(t)
    return 1.0 - Math.sqrt(1.0 - t * t);
  end

  def bounce_out(x)
    n1 = 7.5625;
    d1 = 2.75;
    if (x < 1 / d1)
        return n1 * x * x;
    elsif (x < 2 / d1)
        return n1 * (x -= 1.5 / d1) * x + 0.75;
    elsif (x < 2.5 / d1)
        return n1 * (x -= 2.25 / d1) * x + 0.9375;
    else
        return n1 * (x -= 2.625 / d1) * x + 0.984375;
    end
  end

  def bounce_in(t)
    return 1.0 - bounce_out(1.0 - t);
  end

  def ease(x)
    return 1 - Math.cos((x * Math::PI) / 2);
  end

  def render(canvas)
    @canvas ||= canvas
    @start ||= Hokusai.monotonic

    time = Hokusai.monotonic - @start

    if time > duration
      yield canvas

      return
    else
      case from
      when :top
        @startx ||= canvas.x
        @starty ||= canvas.y - canvas.height
      when :left
        @startx ||= canvas.x - canvas.width
        @starty ||= canvas.y
      when :right
        @startx ||= canvas.x + canvas.width
        @starty ||= canvas.y
      when :bottom
        @startx ||= canvas.x
        @starty ||= canvas.y + canvas.height
      end
      
      @targetx ||= canvas.x
      @targety ||= canvas.y
      
      progress = bounce_in(time.to_f / duration)

      if progress >= 1
        progress = 1.0
      end

      canvas.x = (@startx + (-@startx * progress)) + (@targetx * progress)
      canvas.y = (@starty + (-@starty * progress)) + (@targety * progress)

      yield canvas
    end
  end
end