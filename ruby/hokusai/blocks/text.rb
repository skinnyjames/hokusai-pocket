require_relative "../util/wrap_stream"
require_relative "../util/selection"

class Hokusai::Blocks::Text < Hokusai::Block
  template <<~EOF
  [template]
    empty {
      @keypress="check_copy"
    }
  EOF

  uses(empty: Hokusai::Blocks::Empty)

  computed! :content
  computed :background, default: [255, 255, 255], convert: Hokusai::Color
  computed :color, default: [222,222,222], convert: Hokusai::Color
  computed :selection_color, default: [43, 63, 61], convert: Hokusai::Color
  computed :selection_color_to, default: [0, 33, 233], convert: Hokusai::Color
  computed :animate_selection, default: false
  computed :padding, default: [20.0, 20.0, 20.0, 20.0], convert: Hokusai::Padding
  computed :font, default: nil
  computed :size, default: 15, convert: proc(&:to_i)
  computed :copy_text, default: false

  inject :panel_top
  inject :panel_height
  inject :panel_content_height
  inject :panel_offset
  inject :selection

  attr_accessor :copying, :copy_buffer, :measure_map, :last_content, :breaked, :render_height, :last_size, :last_y,
                :heights_loaded

  def on_mounted
    @copying = false
    @last_content = nil
    @last_size = nil
    @last_y = nil
    @heights_loaded = false
    @copy_buffer = ""
    @measure_map = nil
    @render_height = 0.0
    @breaked = false

    @progress = 0
    @back = false
  end

  def check_copy(event)
    if (event.ctrl || event.super) && event.symbol == :c
      self.copying = true
    end
  end

  def user_font
     font ? Hokusai.fonts.get(font) : Hokusai.fonts.active
  end

  def wrap_cache(canvas, force = false)

    should_splice = last_content != content && !last_content.nil?

    return @wrap_cache unless force || should_splice || !heights_loaded || breaked || @wrap_cache.nil?

    # if there's no cache, new / wrap
    # if the heights aren't loaded - new / wrap
    # if the content changed - use / splice
    # if forced / resized - new / wrap
    if force || !heights_loaded || breaked || @wrap_cache.nil?
      @wrap_cache = Hokusai::Util::WrapCache.new
    end

    self.breaked = false

    # for one big text, we want to use panel_top because canvas.y get's fucked on scroll
    # for looped items, we wawnt to use canvas.y    
    # puts ["canvas.y stream", canvas.y, panel_offset].inspect
    stream = Hokusai::Util::WrapStream.new(width(canvas), canvas.x, canvas.y + (panel_offset || 0)) do |string, extra|
      if w = user_font.measure_char(string, size)
        [w, size]
      else
        [user_font.measure(string, size).first, size]
      end
    end

    if should_splice
      stream.y = @wrap_cache.splice(stream, last_content, content)
    else
      stream.on_text do |wrapped|
        @wrap_cache << wrapped
      end

      stream.wrap(content, nil)
    end

    stream.flush
    self.render_height = stream.y

    if !last_y.nil?
      self.heights_loaded = true
    end

    self.last_y = canvas.y
    self.last_content = content.dup
    self.last_size = size

    @wrap_cache
  end

  def on_resize(canvas)
    self.breaked = true
  end

  def width(canvas)
    canvas.width - padding.width
  end

  def should_refresh(canvas)
    if breaked || last_size != size || (!heights_loaded)
      return true
    end

    false
  end

  # A fragment shader to rotate tint on asteroids
  def fshader
    <<-EOF
    #version 330
    in vec4 fragColor;
    in vec2 fragTexCoord;
    out vec4 finalColor;
    uniform sampler2D texture0;
    uniform vec4 from;
    uniform vec4 to;
    uniform float progress;

    void main() {
      vec4 texelColor = texture(texture0, fragTexCoord) * fragColor;

      finalColor.a = texelColor.a;
      finalColor.rgb = mix(from, to, progress).rgb;
    }
    EOF
  end

  def render(canvas)
    poffset = panel_offset || canvas.y
    pheight = panel_height || canvas.height
    pcheight = panel_content_height ||= canvas.height
    pptop = panel_top.nil? ? canvas.y : panel_top - canvas.y
    ptop = canvas.y + poffset

    cache = wrap_cache(canvas, should_refresh(canvas))
    diff = 0.0

    if selection
      selection.offset_y = poffset if selection.geom.active?
      diff = selection.offset_y - poffset
      selection.diff = diff
    end

    draw do
      tokens = cache.tokens_for(Hokusai::Canvas.new(canvas.width, pheight, canvas.x + padding.left, poffset))
      pad = Hokusai::Padding.new(padding.top, 0.0, 0.0, padding.left)

      if selection && animate_selection
        shader_begin do |command|
          command.fragment_shader = fshader
          command.uniforms = {
            "from" => [selection_color.to_shader_value, HP_SHADER_UNIFORM_VEC4], 
            "to" => [selection_color_to.to_shader_value, HP_SHADER_UNIFORM_VEC4],
            "progress" => [@progress, HP_SHADER_UNIFORM_FLOAT]
          }
        end
      end

      copied = cache.selected_area_for_tokens(tokens, selection, copy: copying || copy_text, padding: pad) do |rect|
        rect(rect.x, rect.y + diff, rect.width, rect.height) do |command|
          command.color = selection_color
        end
      end

      emit("selected", copied) unless copied.nil?

      if copying
        Hokusai.copy(copied.copy)
        self.copying = false
      end

      if copy_text
        emit("copy", copied)
      end

      if selection && animate_selection
        shader_end
      end

      tokens.each do |wrapped|
        # handle selection
        rect = Hokusai::Rect.new(wrapped.x + pad.left, (wrapped.y - (panel_offset || 0.0)) + padding.top, wrapped.width, wrapped.height)
        # draw text
        text(wrapped.text, rect.x, rect.y) do |command|
          command.color = color
          command.size = size
          if font
            command.font = Hokusai.fonts.get(font)
          end
        end
      end
    end

    node.meta.set_prop(:height, render_height)
    emit("height_updated", render_height)

    if @back
      @progress -= 0.02
    else
      @progress += 0.02
    end

    if @progress >= 1 && !@back
      @back = true
    elsif @progress <= 0 && @back
      @progress = 0
      @back = false
    end

    yield canvas
  end
end
