require_relative "../util/wrap_stream"
require_relative "../util/selection"

module Hokusai::Blocks
  class Text < Hokusai::Block
    template <<-EOF
    [template]
      virtual
    EOF

    computed! :content
    computed :static, default: false
    computed :font, default: nil
    computed :size, default: 20, convert: proc(&:to_i)
    computed :color, default: [22, 22, 22], convert: Hokusai::Color
    computed :padding, default: [0.0, 0.0, 0.0, 0.0], convert: Hokusai::Padding
    computed :selection_color, default: [183, 201, 229], convert: Hokusai::Color
    computed :selection_color_to, default: [183, 225, 229], convert: Hokusai::Color
    computed :animate_selection, default: true
    computed :copy_text, default: false
    
    inject :panel_offset
    inject :panel_height
    inject :panel_top
    inject :selection
  
    attr_accessor :counter, :copying

    def initialize(**args)
      @counter = 0
      @last_content = nil
      @copying = false
      @progress = 0
      
      super
    end

    def on_resize(canvas)
      @counter = 0
      @cache = nil
      @last_content = nil

      if selection
        selection.geom.cursor = nil
      end
    end

    def panel?
      !panel_offset.nil?
    end

    def user_font
      font ? Hokusai.fonts.get(font) : Hokusai.fonts.active
    end

    def top(canvas)
      canvas.y + (panel_offset || 0.0) + padding.top
    end

    def panel_height_or_canvas_height(canvas)
      panel_height || canvas.height
    end

    def cache(canvas)
      return @cache if counter >= 2 && static

      @cache = begin
        cache = Hokusai::Util::WrapCache.new
        y = top(canvas)

        stream = Hokusai::Util::WrapStream.new(canvas.width - padding.width, canvas.x, y) do |string, extra|
          if w = user_font.measure_char(string, size)
            [w, size]
          else
            [user_font.measure(string, size).first, size]
          end
        end

        stream.on_text do |wrapped|
          cache << wrapped
        end
        stream.wrap(content, nil)
        stream.flush

        if (stream.y - canvas.y).zero?
          height = size
        else
          height = (stream.y - canvas.y - offset + size).ceil
        end

        node.meta.set_prop(:height, height + padding.height)
        emit("height_updated", height + padding.height)
        @last_content = content

        cache
      end
    end

    def offset
      panel_offset || 0.0
    end

    def height(canvas)
      panel_height || canvas.height
    end

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
      if content.empty? || content.nil?
        yield canvas
      end

      token_cache = cache(canvas) 
      tokens = token_cache.tokens_for(Hokusai::Canvas.new(canvas.width, height(canvas), canvas.x, top(canvas)))

      # token selection
      if selection
        # set up for offset tracking
        selection.offset_y = (panel_offset || 0.0) if selection.geom.active?
        diff = selection.offset_y - (panel_offset || 0.0)
        selection.diff = diff

        if animate_selection
          shader_begin do |command|
            command.fragment_shader = fshader
            command.uniforms = {
              "from" => [selection_color.to_shader_value, HP_SHADER_UNIFORM_VEC4], 
              "to" => [selection_color_to.to_shader_value, HP_SHADER_UNIFORM_VEC4],
              "progress" => [@progress, HP_SHADER_UNIFORM_FLOAT]
            }
          end
        end

        copied = token_cache.selected_area_for_tokens(tokens, selection, copy: copying || copy_text, padding: padding) do |rect|
          y = rect.y + selection.diff
          rect(rect.x, y, rect.width, rect.height) do |command|
            command.color = selection_color
          end
        end

        emit("selected", copied) unless copied.nil?

        if copy_text
          Hokusai.copy(copied.copy)
          emit("copy", copied.copy)
        end

        if animate_selection
          shader_end
        end
      end

      tokens.each do |wrapped|
        # draw text
        text(wrapped.text, wrapped.x + padding.left, wrapped.y + padding.top - offset || 0.0) do |command|
          command.color = color
          command.size = size
          if font
            command.font = user_font
          end
        end
      end

      self.counter += 1 if counter < 2

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
end
