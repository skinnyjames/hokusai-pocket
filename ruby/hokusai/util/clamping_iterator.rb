module Hokusai::Util
  class SegmentRenderer
    attr_reader :iterator, :segment
    attr_accessor :started, :start_select, :stop_select,
                  :select_x, :select_width

    def initialize(segment, iterator)
      @segment = segment
      @iterator = iterator
      @started = false
      @start_select = 0
      @stop_select = nil
      @select_x = nil
      @select_width = nil
    end

    def draw(font_size, boundary, selection: nil)
      selection_extract(font_size, boundary, selection: selection)
      draw_text(font_size, boundary)
      selection_update(selection)
      self.start_select = 0.0
      self.stop_select = nil
    end

    def selection_extract(font_size, boundary, selection: nil)
      local_x = iterator.x
      y = iterator.y
      hit_box = Hokusai::Rect.new(0, 0, 0, 0)

      if @iterator.clamping.markdown
        segment.groups.each do |group|
          group.chars.each do |char|
            if can_render_inside(font_size, boundary) && segment.char_is_selected(char)
              self.select_x ||= local_x
              self.select_width = select_width.nil? ? char.width : (select_width + char.width)
      
              if selector = selection
                if segment.select_begin == char.offset && selector.up? && !iterator.cursor_set && !selector.started
                  iterator.cursor_position = [local_x, y, char.width, font_size.to_f]
                  iterator.cursor_set = true
                  selector.started = true
                elsif segment.select_end == char.offset && selector.down? && started
                  iterator.cursor_position = [local_x + char.width, y, char.width, font_size.to_f]
                end
              end
            elsif !segment.select_end.nil? && segment.select_end < char.offset
              selection&.started = false
            end
          hit_box = Hokusai::Rect.new(local_x, y, char.width, font_size.to_f)
          iterator.on_char_cb&.call(char, hit_box, char.offset)

          if selector = selection
            if selector.active? && selector.selected(local_x, y, char.width.to_f, font_size.to_f)
              self.stop_select = char.offset

              unless started
                self.start_select = char.offset
                self.started = true
              end
            end
          end

          local_x += char.width
        end
      end
      else

        segment.chars.each do |char|
          if can_render_inside(font_size, boundary) && segment.char_is_selected(char)
            self.select_x ||= local_x
            self.select_width = select_width.nil? ? char.width : (select_width + char.width)
    
            if selector = selection
              if segment.select_begin == char.offset && selector.up? && !iterator.cursor_set && !selector.started
                iterator.cursor_position = [local_x, y, char.width, font_size.to_f]
                iterator.cursor_set = true
                selector.started = true
              elsif segment.select_end == char.offset && selector.down? && started
                iterator.cursor_position = [local_x + char.width, y, char.width, font_size.to_f]
              end
            end
          elsif !segment.select_end.nil? && segment.select_end < char.offset
            selection&.started = false
          end

          hit_box = Hokusai::Rect.new(local_x, y, char.width, font_size.to_f)
          iterator.on_char_cb&.call(char, hit_box, char.offset)

          if selector = selection
            if selector.active? && selector.selected(local_x, y, char.width.to_f, font_size.to_f)
              self.stop_select = char.offset

              unless started
                self.start_select = char.offset
                self.started = true
              end
            end
          end

          local_x += char.width
        end

        # hit_box.x = local_x
        # hit_box.y = y
        # hit_box.width = char.width
        # hit_box.height = font_size.to_f


      end

      return unless select_x && select_width
      iterator.on_draw_selection_cb&.call(select_x, y, select_width, font_size.to_f)
    end

    def selection_update(selection)
      return unless selection&.active?
      segment.make_selection(start_select, stop_select)

      return if stop_select.nil?

      iterator.start_select ||= start_select + iterator.cursor_offset
      iterator.stop_select = stop_select + iterator.cursor_offset
    end

    def draw_text(font_size, boundary)
      if can_render_inside(font_size, boundary)
        x = @iterator.x

        if @iterator.clamping.markdown
          segment.groups.each do |group|
            text = iterator.clamping[group.offset, group.size]

            if text == "\n"
              next
              # x += group.width
            end
            
            @iterator.on_draw_cb&.call(text, x, y, group)

            x += group.width
          end
        else
          @iterator.on_draw_cb&.call(text, x, y, segment)
        end
      end

      @iterator.y += font_size
      @iterator.height += font_size
    end

    def x
      iterator.x
    end

    def y
      iterator.y
    end

    def text
      iterator.clamping[segment.offset, segment.size]
    end

    def can_render_inside(font_size, boundary)
      iterator.y >= boundary[0] && iterator.y + font_size <= boundary[1]
    end
  end

  class ClampingIterator
    attr_reader :segments, :clamping,
                :on_draw_cb, :on_draw_selection_cb,
                :on_selection_change_cb, :on_cursor_change_cb,
                :on_char_cb

    attr_accessor :produced, :height, :cursor_offset, :x, :y,
                  :start_select, :stop_select, :cursor_position, :cursor_set

    def initialize(clamping, x, y)
      @clamping = clamping
      @x = x
      @y = y
      @height = 0
      @cursor_offset = 0
      @cursor_set = false
      @i = 0
    end

    def reset
      @i = 0
    end

    def debug
      clamping.debug
    end

    def segments
      clamping.segments
    end
    
    def next
      if @i < segments.size
        SegmentRenderer.new(segments[@i], self)
      else
        if position = cursor_position
          on_cursor_change_cb&.call(position)
        end

        if start = start_select
          on_selection_change_cb&.call(start, stop_select)
        end

        nil
      end
    ensure
      @i += 1
    end

    def cursor_y
      y
    end

    def cursor_x
      x
    end

    def on_draw(&block)
      @on_draw_cb = block
    end

    def on_draw_selection(&block)
      @on_draw_selection_cb = block
    end

    def on_selection_change(&block)
      @on_selection_change_cb = block
    end

    def on_cursor_change(&block)
      @on_cursor_change_cb = block
    end

    def on_char(&block)
      @on_char_cb = block
    end
  end
end