# Public: A text rendering component
module Hokusai
  module Blocks
    class Text < Hokusai::Block
      template <<-EOF
      [template]
        virtual
      EOF

      uses(empty: Hokusai::Blocks::Empty)

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
      computed :min_height, default: nil
      computed :max_height, default: nil

      inject :panel_offset
      inject :panel_height
      inject :panel_top
      inject :panel_autoclip
      inject :selection

      attr_accessor :counter, :copying, :last_width

      def initialize(**args)
        @counter = 0
        @last_width = 0.0
        @last_content = nil
        @copying = false
        @progress = 0
        
        super
      end

      def on_resize(canvas)
        @counter = 0
        @cache = nil
        @last_content = nil
        @last_width = 0.0

        if selection
          p ["resize"]
          selection.cursor = nil
        end
      end

      def panel?
        !panel_offset.nil?
      end

      def user_font
        font ? Hokusai.fonts.get(font) : Hokusai.fonts.active
      end

      def start_top(canvas)
        t = canvas.y + padding.top
        t += offset if panel_autoclip
        t += panel_top || 0.0
        t
      end

      def top
        offset + padding.top + (panel_top || 0.0)
      end

      def panel_height_or_canvas_height(canvas)
        panel_height || canvas.height
      end

      def cache(canvas)
        return @cache if counter >= 2 && (static || @last_content == content && @last_width == canvas.width)

        if @last_width != canvas.width
          self.counter = 0
          
          @last_width = canvas.width
        elsif @last_content != content && @cache
          # splicing in content
          y = start_top(canvas)

          stream = Hokusai::Util::WrapStream.new(canvas.width - padding.width, canvas.x, 0.0) do |string, extra|
            if w = user_font.measure_char(string, size)
              [w, size]
            else
              [user_font.measure(string, size).first, size]
            end
          end

          new_y = @cache.splice(stream, content, selection: selection)
          if (new_y - y - padding.top).zero?
            height = size
          else
            height = (new_y - y - padding.top + size).ceil
          end

          if content.end_with?("\n")
            height += self.size
          end
          
          if min_height && height < min_height
            height = min_height
          elsif max_height && height > max_height
            height = max_height
          end
          
          node.meta.set_prop(:height, height + padding.height)
          emit("height_updated", height + padding.height)
          @last_content = content.dup

          return @cache
        end
        
        @cache = begin
          cache = Hokusai::Util::WrapCache.new
          y = start_top(canvas)
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

          if (stream.y - y - padding.top).zero?
            height = size
          else
            height = (stream.y - y - padding.top + size).ceil
          end

          if content.end_with?("\n")
            height += self.size
          end
          
          if min_height && height < min_height
            height = min_height
          elsif max_height && height > max_height
            height = max_height
          end

          node.meta.set_prop(:height, height + padding.height)
          emit("height_updated", height + padding.height)
          @last_content = content.dup

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
        # @min_height = canvas.height
        if content.nil? || content.size.zero?

          height = min_height || size
          node.meta.set_prop(:height, height)
          emit("height_updated", height)
          if selection && node.meta.focused
            

            selection.focus_id = node.uuid
            selection.pos.cursor_index = 0
            selection.pos.positions = nil
            # p ["setting cursor to", canvas.y.round(2) + offset.round(2) + padding.top]
            #           selection.geom!
            # p ["before cursor", selection.cursor]
            selection.state = :geom
            selection.geom.modified = true
            selection.offset_y = offset
            selection.cursor = [canvas.x + padding.left, canvas.y.round(2) + offset.round(2), 3.5, size].dup
            selection.pos!(false)
            # p ["after cursor", content[0..20], selection.cursor]
          end

          yield canvas
          return
        end

        token_cache = cache(canvas)
        # if content is removed or added from a previous sibling text node, the y offset of this node will change.
        # we need to calculate and persist the diff.
        diff = canvas.y.round(2) + offset.round(2) - token_cache.tokens.first.y.round(2)
        token_cache.diff_y = diff
        tokens = token_cache.tokens_for(Hokusai::Canvas.new(canvas.width, height(canvas), canvas.x, top))

        # token selection
        if selection && (node.meta.focused || node.uuid == selection.focus_id)
          if selection.focus_id != node.uuid && !node.meta.focused
            selection.clear
          end

          selection.cursor = nil unless node.meta.focused
          selection.focus_id = node.uuid
          selection.offset_y = offset

          if animate_selection && selection.geom?
            shader_begin do |command|
              command.fragment_shader = fshader
              command.uniforms = {
                "from" => [selection_color.to_shader_value, HP_SHADER_UNIFORM_VEC4], 
                "to" => [selection_color_to.to_shader_value, HP_SHADER_UNIFORM_VEC4],
                "progress" => [@progress, HP_SHADER_UNIFORM_FLOAT]
              }
            end
          end

          token_cache.selected_area_for_tokens(tokens, selection, padding: padding) do |rect|
            rect(rect.x, rect.y, rect.width, rect.height) do |command|
              command.color = selection_color
            end
          end

          if copy_text
            copystuff = token_cache.selected_text(content, selection)

            Hokusai.copy(copystuff)
            emit("copy", copystuff)
          end

          if animate_selection && selection.geom?
            shader_end
          end
        end

        tokens.each do |wrapped|
          # draw text
          text(wrapped.text, wrapped.x + padding.left, wrapped.y + diff + padding.top - offset || 0.0) do |command|
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
end


