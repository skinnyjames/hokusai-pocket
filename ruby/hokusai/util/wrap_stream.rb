
module Hokusai::Util
  # Public: Payload for [Hokusai::Util::WrapStream#on_text](/api/Hokusai/Util/WrapStream.html#on-text-block)
  class Wrapped
    attr_accessor :y
    attr_accessor :text, :x, :width, :height, :extra, :widths, :positions
    
    def initialize(text, rect, extra, widths:, positions:)
      @text = text
      @x = rect.x
      @y = rect.y
      @width = rect.width
      @height = rect.height
      @widths = widths
      @extra = extra
      @positions = positions
    end

    def range
      positions.first..positions.last
    end
  end

  class WrapCachePayload
    attr_accessor :copy, :positions, :cursor
    
    def initialize(copy, positions, cursor)
      @copy = copy
      @positions = positions
      @cursor = cursor
    end
  end

  # Public: A cache that stores the results of WrapStream.
  #         Utiltiy methods are provided to quickly fetch a subset of tokens
  #         Based on a given window's coordinates (canvas)
  class WrapCache
    attr_accessor :tokens, :diff_y

    def diff(new_content)
      return nil if tokens.empty? 
      old_len = tokens.last.positions.last + 1
      delta = new_content.length - old_len

      sidx = 0
      while sidx < tokens.size
        t = tokens[sidx]
        start = t.positions.first
        break unless new_content[start, t.text.length] == t.text
        sidx += 1
      end
      
      return nil if sidx == tokens.size && delta.zero? # truly identical

      eidx = tokens.size - 1
      while eidx > sidx
        t = tokens[eidx]
        new_start = t.positions.first + delta
        unless new_start >= 0 && new_content[new_start, t.text.length] == t.text
          break
        end

        eidx -= 1
      end

      eidx += 1 if delta.negative?
      eidx = tokens.size - 1 if eidx >= tokens.size
      sidx = eidx if sidx >= eidx

      old_first = tokens[sidx].positions.first
      old_last  = tokens[eidx].positions.last + 1
      new_first = old_first
      new_last  = old_last + delta

      [sidx, eidx, (old_first...old_last), (new_first...new_last)]
    end

    def splice(stream, new_content, selection: nil)
      sidx, eidx, oldrange, newrange = diff(new_content)
      return if sidx.nil? # no change

      new_data = new_content[newrange]
      old_text_callback = stream.on_text_cb
      newtokens = []
      newheight = 0.0
      diff = newrange.size - oldrange.size

      yold = tokens[sidx].y
      stream.on_text do |wrapped|
        unless wrapped.positions.empty?
          newheight += wrapped.height
          wrapped.y += yold
          wrapped.positions.map! { |pos| pos + oldrange.first }
          newtokens << wrapped
        end
      end

      stream.wrap(new_data, nil)
      stream.flush

      oldheight = tokens[sidx..eidx].reduce(0.0) { |memo, token| memo + token.height }
      heightdiff = newheight - oldheight #+ tokens.last.height

      tokens[eidx + 1..].each do |token|
        token.y += heightdiff
        token.positions.map! { |pos| pos + diff }
      end

      if newtokens.empty?
        tokens[sidx..eidx] = nil
        tokens.reject!(&:nil?)
      else
        tokens[sidx..eidx] = newtokens
      end

      stream.on_text(&old_text_callback)
      tokens.last.y
    end

    attr_accessor :offset_pos

    def initialize
      @diff_y = 0.0
      @tokens = []
    end

    def selected_text(compare, selection)
      return "" if selection.pos.positions.nil?

      posrange = selection.pos.positions.first..selection.pos.positions.last
      tokenrange = tokens.first.positions.first..tokens.last.positions.last

      if tokenrange.first > posrange.first
        min = tokenrange.first
      else
        min = posrange.first
      end

      if tokenrange.last < posrange.last
        max = tokenrange.last
      else
        max = posrange.last
      end

      range = (min)..(max)
      if range.begin > range.end
        range = range.end..range.begin
      end

      compare[range].dup
    end

    # Public: Adds a token
    # 
    # token - Hokusai::Util::Wrapped 
    # 
    # Returns nothing
    def <<(element)
      @tokens << element unless element.positions.empty?
    end

    def bsearch(canvas)
      low = 0
      high = tokens.size - 1

      return 0 if high.zero?

      while low <= high
        mid = low + (high - low) / 2

        if matches(tokens[mid], canvas)
          return mid
        end

        if tokens[mid].y + diff_y > canvas.y
          high = mid - 1
        end

        if tokens[mid].y + diff_y < canvas.y
          low = mid + 1
        end
      end

      return nil
    end

    def matches(wrapped, canvas)
      wrapped.y + diff_y >= canvas.y && wrapped.y + diff_y <= canvas.y + canvas.height
    end

    # Public: Populate the selection positions from geometry and yield selection areas
    #
    # target_tokens - an Array(Hokusai::Util::Wrapped)
    # selector - a Hokusai::Util::Selection
    # block - a callback which takes a param of Hokusai::Rect
    #
    # Returns nothing
    def selected_area_for_tokens(target_tokens, selector, padding: Hokusai::Padding.default)
      return if selector.nil? || !selector.selecting? || target_tokens.size.zero?

      x = nil
      tw = 0.0
      cy = nil
      cursor = nil
      pcursor = nil
      lcursor = nil
      lpcursor = nil
      position_buffer = nil
      required_range = target_tokens.first.positions.first..target_tokens.last.positions.last

      # each token should represent a wrapped line of text
      # each token has a array of widths that repesent each char width in that line
      if selector.action == :all
        selector.pos.positions = tokens.first.positions.first..tokens.last.positions.last
        selector.pos.cursor_index = tokens.last.positions.last
        selector.action = :collect
        return
      end

      tokens.each_with_index do |token, ti|
        next unless required_range.cover?(token.positions.first..token.positions.last) || selector.action == :collect || (required_range.include?(token.positions.first) && required_range.include?(token.positions.last))

        if (selector.action == :up || selector.action == :down) && (token.positions.first..token.positions.last).include?(selector.pos.cursor_index)
          selector.column ||= token.positions.index(selector.pos.cursor_index)

          case selector.action
          when :up
            if ntoken = ti > 0 && tokens[ti  - 1]
              ci = ntoken.positions[selector.column] || ntoken.positions.last
              selector.pos.concat (ci..selector.pos.cursor_index)
              selector.pos.cursor_index = ci
              selector.geom.move_up(token.height)
            end
          when :down
            if ntoken = tokens[ti + 1]
              ci = ntoken.positions[selector.column] || ntoken.positions.last
              selector.pos.concat (selector.pos.cursor_index..ci)
              selector.pos.cursor_index = ci
              selector.geom.move_down(token.height)
            end
          end

          selector.action = nil
          return
        end

        tx = token.x + padding.left
        ty = token.y + padding.top + diff_y

        if token.y != cy
          x = nil
          cy = token.y
          tw = 0.0
        end
        
        token.widths.each_with_index do |w, i|
          if selector.pos.cursor_index
            case selector.action
            when :word
              if (selector.pos.cursor_index == token.positions[i])
                min = i
                max = i

                loop do
                  # go backward until word boundary
                  break if min <= 0
                  break if token.text[min - 1].nil?
                  break if token.text[min - 1] =~ /[^A-Za-z0-9]/
                  min -= 1
                end

                loop do
                  break if token.text[max + 1].nil?
                  break if token.text[max + 1] =~ /[^A-Za-z0-9]/
                  max += 1
                end

                position_buffer = token.positions[min]..token.positions[max]
                ay = cy + padding.top - selector.offset_y
                sumx = token.x + padding.left
                if min > 1
                  sumx += token.widths[0...min].reduce(&:+)
                end
                sumwidth = token.widths[min..max].reduce(&:+)

                yield Hokusai::Rect.new(sumx, ay, sumwidth, token.height)

                # selector.pos!
                selector.pos.cursor_index = token.positions[max]
                selector.cursor = [sumx + sumwidth, cy + padding.top, 0.5, token.height]
                selector.geom.click_pos = nil
                selector.pos.positions = position_buffer.first..position_buffer.last if position_buffer 
                selector.pos.freeze!
                selector.action = nil
                return
              end
            when :line
              if selector.pos.cursor_index == token.positions[i] #|| selector.geom? && selector.geom.clicked(tx, by, (w / 2), token.height)
                # line selected
                position_buffer = token.positions.first..token.positions.last
                ay = cy + padding.top - selector.offset_y
                sum = token.widths.sum
                yield Hokusai::Rect.new(token.x + padding.left, ay, sum, token.height)

                # selector.pos!
                selector.pos.cursor_index = token.positions.last
                selector.cursor = [token.x + padding.left + sum, cy + padding.top, 0.5, token.height]
                selector.pos.positions = position_buffer.first..position_buffer.last if position_buffer
                selector.geom.click_pos = nil
                selector.pos.freeze!
                selector.action = nil
                return
              end
            end
          end

          # if we are currently selecting by geometry, we need to populate the widths
          # cursor, and cursor_index, so that we can switch over.
          if selector.geom? && selector.geom.selected(tx, ty, w, token.height)
            if (selector.geom.up?)
              cursor ||= [tx, ty, 0.5, token.height]
              pcursor ||= token.positions[i]
            else
              cursor = [tx + w, ty, 0.5, token.height]
              pcursor = token.positions[i]
            end

            if position_buffer.nil? 
              position_buffer = token.positions[i]..token.positions[i]
            else
              position_buffer = position_buffer.first..token.positions[i]
            end

            if x.nil?
              x = tx
            end

            tw += w
          # we are now selecting by position.
          elsif selector.pos? && selector.pos.selected(token.positions[i])
            if selector.pos.cursor_index == selector.pos.positions.first
              cursor ||= [tx, ty, 0.5, token.height]
              pcursor ||= token.positions[i]
            elsif selector.pos.cursor_index == selector.pos.positions.last
              cursor = [tx + w, ty, 0.5, token.height]
              pcursor = token.positions[i]

            elsif selector.pos.cursor_index + 1 == token.positions[i]
              cursor = [tx, ty, 0.5, token.height]
              pcursor = token.positions[i] - 1
            end

            if position_buffer.nil? 
              position_buffer = token.positions[i]..token.positions[i]
            else
              position_buffer = position_buffer.first..token.positions[i]
            end

            if x.nil?
              x = tx
            end

            tw += w

          # cursor handling when there is no selection
          elsif selector.pos? && selector.pos.cursor_index && selector.pos.cursor_index + 1 == token.positions[i]
            cursor = [tx, ty, 0.5, token.height]
            pcursor = selector.pos.cursor_index
          elsif selector.pos? && selector.pos.cursor_index && selector.pos.cursor_index - 1 == token.positions[i]
            cursor = [tx + w, ty, 0.5, token.height]
            pcursor = selector.pos.cursor_index
          elsif selector.pos? && selector.pos.cursor_index && selector.pos.cursor_index == token.positions[i]
            if token.text[i] == "\n"
              cursor = [token.x + padding.left, ty + token.height, 0.5, token.height]
            else
              cursor = [tx + w, ty, 0.5, token.height]
            end
            pcursor = selector.pos.cursor_index
            #selector.pos.offset += 1
          elsif selector.geom? && selector.pos.cursor_index.nil? && selector.geom.clicked(tx + (w/2.0), ty, (w/2.0), token.height)
            cursor ||= [tx + w, ty, 0.5, token.height]
            pcursor = token.positions[i]
          elsif selector.geom? && selector.pos.cursor_index.nil? && selector.geom.clicked(tx, ty, (w / 2), token.height)
            cursor ||= [tx, ty, 0.5, token.height]
            if token.positions[i]
              pcursor ||= token.positions[i] - 1
            else
              pcursor ||= token.positions[i]
            end
          elsif selector.geom? && selector.pos.cursor_index.nil? && selector.pos.positions.nil? && selector.geom.clicked_on_line(token.x, ty, token.width, token.height)
            pcursor = token.positions[i].zero? ? 0 : token.positions[i]
            cursor = [tx, ty + w, 0.5, token.height]
          else
            lpcursor = token.positions[i]
            lcursor = [tx, ty + w, 0.5, token.height]
          end

          # move the current x forward
          tx += w
        end
        
        if !x.nil?
          # if we have a selection, yield it.
          ay = cy + padding.top - selector.offset_y + diff_y
          yield Hokusai::Rect.new(x, ay, tw, token.height)

          tw = 0.0
          x = nil
        end
      end

      # we have cursors
      if pcursor
        selector.pos.cursor_index = pcursor unless selector.pos.frozen?
        selector.cursor = cursor
      end

      # we have a position array
      if !position_buffer.nil? && !selector.pos.frozen?
        selector.pos.concat position_buffer 
      end
    end

    # Public: Get cached tokens for a given Hokusai::Canvas
    # 
    # canvas - a Hokusai::Canvas
    # 
    # Return Array(Hokusai::Util::Wrapped)
    def tokens_for(canvas)
      index = bsearch(canvas)

      return [] if index.nil?
  
      lindex = index.zero? ? index : index - 1
      rindex = index + 1

      while rindex < tokens.size - 1 && matches(tokens[rindex], canvas)
        rindex += 1
      end

      while lindex > 0 && matches(tokens[lindex], canvas)
        lindex -= 1
      end

      tokens[lindex..rindex].clone
    end
  end

  # Public: A disposable streaming text wrapper
  #         tokens can be appended onto it, where it they will break on a given width.
  #         Opaque payloads can be passed for each token, which will be provided to callbacks.
  #         This makes it suitable for processing and wrapping markdown/html/tokenized text
  #
  # Examples
  # 
  #   stream = Hokusai::Util::WrapStream.new(canvas.width, canvas.x, canvas.y) do |string, extra|
  #     # String is the data being wrapped
  #     # Extra is the payload provided for that string
  #     # Callbacks takes a [width, height] as response
  #     [Hokusai.fonts.get("default").measure(string, size).first, size]
  #   end
  #   #
  #   # subscribe to emitted tokens Hokusai::Util::Wrapped
  #   stream.on_text do |wrapped|
  #     draw do
  #       text(wrapped.text, wrapped.x, wrapped.y) do |command|
  #         command.color = wrapped.extra[:color]
  #       end
  #     end
  #   end
  #   # Feed the stream content
  #   stream.wrap("Hello this red text might be wrapped over the width", { color: Hokusai::Color.new(222,22,22) })
  #   stream.wrap("This is blue text", { color: Hokusai::Color.new(22,22,222) })
  #   # flush remaining tokens
  #   stream.flush
  #   # stream#y now holds the total height of the wrapped tokens
  #   stream.y
  #
  class WrapStream
    attr_accessor :buffer, :x, :y, :origin_y, :current_width, :stack, 
                  :widths, :offset_pos, :current_position, :positions, 
                  :last_size, :on_text_cb
    attr_reader :width, :origin_x, :on_text_cb

    # Public: constructor for WrapStream
    # 
    # width - a float. When text exceeds this width, it will wrap to a new line
    # origin_x - where the x value starts (default: 0.0)
    # origin_y - where the y value starts (default: 0.0)
    # block - a callback to measure a given string.  Callback must return an array containing the width and height of the string
    def initialize(width, origin_x = 0.0, origin_y = 0.0, origin_offset = 0, &measure)
      @width = width            # the width of the container for this wrap
      @measure_cb = measure     # a measure callback that returns the width/height of a given char (takes 2 params: a char and an token payload)
      @on_text_cb = ->(_) {}    # a callback that receives a wrapped token for a given line.  (takes a Hokusai::Util::Wrapped paramter)

      @origin_x = origin_x      # the origin x coordinate, x will reset to this
      @x = origin_x             # the marker for x coord, this is used to track against the width of a given line
      @y = origin_y             # the marker for the y coord, this grows by <size> for each line, resulting in the height of the wrapped text
      @current_width = 0.0      # the current width of the buffer
      @stack = []               # a stack storing buffer offsets with their respective token payloads.
      @buffer = ""              # the current buffer that the stack represents.
      
      @offset_pos = origin_offset
      @current_position = 0     # the current char index
      @positions = []           # a stack of char positions, used for editing
      @widths = []              # a stack of char widths, used later in selection

      @last_size = 0.0
    end

    NEW_LINE_REGEX = /\n/

    # Public: Appends (text) to the wrap stream.
    #         If the text supplies causes the buffer to grow beyond the supplied width
    #         The buffer will be flushed to the (on_text_cb) callback.
    #
    # text - text to append to this wrap stream
    # extra - an opaque payload that will be passed to callbacks
    # 
    # Returns nothing
    def wrap(text, extra)
      offset = 0
      size = text.size
      
      # appends the initial stack value for this text
      stack << [((buffer.size)..(text.size + buffer.size - 1)), extra]

      # char-by-char processing.
      while offset < size
        char = text[offset]
        self.current_position = offset_pos

        w, h = measure(char, extra)

        # this char is actually a newline.
        if NEW_LINE_REGEX.match(char)
          self.widths << 0
          self.buffer << char
          self.positions << current_position
          flush

          # append the rest of this text to the stack.
          stack << [(0...(text.size - offset - 1)), extra]
          self.y += h
          self.x = origin_x
          offset += 1
          self.offset_pos += 1

          next
        end

        # adding this char will extend beyond the provided width
        if w + current_width >= width
          # if this is a space in the second half of this line, 
          # split the buffer @ it's index and render
          idx = buffer.rindex(" ")
          if !idx.nil?
            cur = []
            nex = []

            found = false

            # we need to split up the buffer and the ranges.
            while payload = stack.shift
              range, xtra = payload

              # this range contains the space
              # we will split the stack here
              if range.include?(idx)
                cur << [(range.begin..idx), xtra]
                nex << [(0..(range.end - idx - 1)), xtra] unless idx == range.end
              
                found = true
              # the space has not been found
              # append to first stack
              elsif !found
                cur << payload
              # the space has been found
              # append to second stack.
              # (note: we need to subtract the idx from the range because 
              #        we are flushing everything before the space)
              else
                nex << [((range.begin - idx - 1)..(range.end - idx - 1)), xtra] 
              end
            end

            # get the string values from the buffer
            scur = buffer[0..idx]
            snex = buffer[(idx + 1)..-1]

            wcur = widths[0..idx]
            wnex = widths[(idx + 1)..-1]

            pcur = positions[0..idx]
            pnex = positions[(idx + 1)..-1]

            # set the buffer and stack to everything before the space
            self.buffer = scur
            self.widths = wcur
            self.stack = cur
            self.positions = pcur

            flush

            # set the buffer and stack to everything after the space
            self.buffer = snex + char
            self.widths = wnex.concat([w])
            self.positions = pnex.concat([current_position])
            self.stack = nex
            self.x = origin_x
            self.current_width = widths.sum#measure(buffer, xtra).first


            # bump the height
            self.y += h
          # no space: force a break on the char.
          else
            flush

            self.current_width = w
            self.y += h
            self.buffer = text[offset]
            self.widths = [w]
            self.positions = [current_position]
            stack << [(0...(text.size - offset)), extra]
          end
        # append this char does NOT extend beyond the width
        else
          self.current_width += w
          buffer << char
          widths << w
          positions << current_position
        end

        offset += 1
        self.offset_pos += 1
      end
    end

    # Public: Flushes the current buffer/stack.
    def flush
      stack.each do |(range, extra)|
        content = buffer[range]
        size = content.size
        content_width, content_height = measure(content, extra)

        wrap_and_call(content, content_width, content_height, extra, widths[range], positions[range])
        self.x += content_width
      end


      self.buffer = ""
      self.current_width = 0.0
      stack.clear
      widths.clear
      positions.clear
      self.x = origin_x
    end

    # Public: A callback that is called whenever the stream is wrapped or flushes
    # 
    # block - the provided callback
    # 
    # Returns nothing
    def on_text(&block)
      @on_text_cb = block
    end

    private

    def wrap_and_call(text, width, height, extra, item_widths, item_positions)
      rect = Hokusai::Rect.new(x, y, width, height)
      @on_text_cb.call Wrapped.new(text.dup, rect, extra, widths: item_widths.dup, positions: item_positions.dup)
    end

    def measure(string, extra)
      @measure_cb.call(string, extra)
    end
  end
end
