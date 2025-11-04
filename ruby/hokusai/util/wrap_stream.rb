
module Hokusai::Util
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

  # A cache that stores the results of WrapStream.
  # Utiltiy methods are provided to quickly fetch a subset of tokens
  # Based on a given window's coordinates (canvas)
  class WrapCache
    attr_accessor :tokens

    # returns range denoting the index of the changed lines
    # from 2 different strings.
    # NOTE: the change must be consecutive
    def self.diff(first, second)
      arr = (0..first.length).to_a

      v = arr.bsearch do |i|
        first.rindex(second[0..i]) != 0
      end

      # bounds checks
      v = first.size if v.nil?
      v -= 1 if first[v] == "\n"

      a = 0
      while true
        if first[v] == "\n"
          a = v + 1
          break
        elsif v.zero?
          a = v
          break
        end
        v -= 1
      end

      b = a
      while true
        if first[b].nil?
          b = first.size - 1
          break
        elsif first[b] == "\n"
          break
        end
        b += 1
      end

      a..b
    end

    def initialize
      @tokens = []
    end

    def <<(element)
      @tokens << element
    end

    def splice(stream, last_content, new_content, selection: nil)
      change_line_indicies = WrapCache.diff(last_content, new_content)
      new_changed_line_indicies = WrapCache.diff(new_content, last_content)

      new_data = new_content[new_changed_line_indicies]
      old_text_callback = stream.on_text_cb
      records = []
      # the height of the new records
      records_height = 0.0

      stream.on_text do |wrapped|
        unless wrapped.positions.empty?
          records_height += wrapped.height
          wrapped.positions.map! do |pos|
            pos + change_line_indicies.begin
          end
          records << wrapped
        end
      end

      stream.wrap(new_data, nil)
      stream.flush

      # puts ["original.tokens.last.y", tokens.last.y].inspect

      # splice in new tokens
      #
      # update the new positions
      # NOTE: still need to udpate the y positions with the 
      # records.each do |record|
      #   records_height += record.height
      #   record.positions.map! do |pos|
      #     pos + change_line_indicies.begin
      #   end
      # end

      diff_pos = (new_changed_line_indicies.end - change_line_indicies.end)
      new_tokens = []
      found = false
      last_token = nil
      new_last_tokens_height = 0.0
      last_tokens_height = 0.0
      insert_index = 0

      while token = tokens.shift
        next if token.positions.empty?
        if token.range.begin >= change_line_indicies.begin && token.range.end <= change_line_indicies.end
          # this is a match
          # we want to remove these tokens from the list...and then sub in our new tokens.
          last_token = token
          last_tokens_height += token.height
          found = true
          next
        end

        if found
          token.y += (records_height - last_tokens_height)

          token.positions.map! do |pos|
            pos + diff_pos
          end
        else
          insert_index += 1
          new_last_tokens_height += token.height
        end

        new_tokens << token
      end

      records.each do |record|
        record.y += new_last_tokens_height
      end

      # puts ["insert", records.first.y, records.map(&:height).sum, insert_index, new_last_tokens_height].inspect

      new_tokens.insert(insert_index, *records)
      self.tokens = new_tokens
      

      # i = 0
      # tokens.each do |token|
      #   # puts ["token", token].inspect
      #   token.positions.each do |n|
      #     if n != i
      #       puts ["Mismatch token", token, i, n].inspect
      #     end

      #     i += 1
      #   end
      # end

      # restore callback
      stream.on_text(&old_text_callback)
      # return y
      tokens.last.y + tokens.last.height
    end

    def bsearch(canvas)
      low = 0
      high = tokens.size - 1

      while low <= high
        mid = low + (high - low) / 2

        if matches(tokens[mid], canvas)
          return mid
        end

        if tokens[mid].y > canvas.y
          high = mid - 1
        end

        if tokens[mid].y < canvas.y
          low = mid + 1
        end
      end

      return nil
    end

    def matches(wrapped, canvas)
      wrapped.y >= canvas.y && wrapped.y <= canvas.y + canvas.height
    end

    #  arrows = cursor index
    #  letters = selected positions
    #                          
    #  │     │      │     │     │  
    #  │  A  │   B  │  C  │  D  │  
    #  │     │      │     │     │  
    #  ▼  0  ▼   1  ▼  2  ▼  3  ▼  
    #                           
    #  -1    0      1     2     3  
    #                            
    def selected_area_for_tokens(tokens, selector, copy: false, padding: Hokusai::Padding.default)
      return if selector.nil? || !selector.selecting?

      copy_buffer = ""
      x = nil
      tw = 0.0
      cy = nil
      position_buffer = []
      cursor = nil
      pcursor = nil

      tokens.each do |token|
        tx = token.x + padding.left
        ty = token.y + padding.top

        if token.y != cy
          x = nil
          cy = token.y
          tw = 0.0
        end

        token.widths.each_with_index do |w, i|
          by = selector.geom.frozen? ? ty : ty - selector.offset_y
          sy = ty

          if (selector.geom? && selector.geom.selected(tx, by, w, token.height))
            if (selector.geom.left? || selector.geom.up?)
              cursor ||= [tx, sy, 0.5, token.height]
              pcursor ||= token.positions[i]
            else
              # puts ["set selection cursor: #{sy}"]
              cursor = [tx + w, sy, 0.5, token.height]
              pcursor = token.positions[i]
            end

            position_buffer << token.positions[i]

            if copy
              copy_buffer += token.text[i]
            end

            if x.nil?
              x = tx
            end

            tw += w
          elsif selector.pos? && selector.pos.selected(token.positions[i])
            # puts ["pos 1"]
            if selector.pos.cursor_index == selector.pos.positions.first
              cursor ||= [tx, sy, 0.5, token.height]
              pcursor ||= token.positions[i]
            elsif selector.pos.cursor_index == selector.pos.positions.last
              cursor = [tx + w, sy, 0.5, token.height]
              pcursor = token.positions[i]
            elsif selector.pos.cursor_index + 1 == token.positions[i]
              cursor = [tx, sy, 0.5, token.height]
              pcursor = token.positions[i] - 1
            end

            position_buffer << token.positions[i]

            if copy
              copy_buffer += token.text[i]
            end

            if x.nil?
              x = tx
            end

            tw += w

          # [0, [0]]
          elsif selector.pos? && selector.pos.cursor_index && selector.pos.cursor_index + 1 == token.positions[i]
            # puts "pos 2"
            cursor = [tx, sy, 0.5, token.height]
            pcursor = token.positions[i] - 1
            # position_buffer = selector.pos.positions

            # if copy
            #   copy_buffer += token.text[i]
            # end

          elsif selector.pos? && selector.pos.cursor_index && selector.pos.cursor_index == token.positions[i]
            # puts "pos 3"
            cursor = [tx + w, sy, 0.5, token.height]
            pcursor = selector.pos.cursor_index
            # position_buffer = selector.pos.positions
          elsif selector.geom? && selector.geom.clicked(tx, by, (w / 2), token.height)
            cursor = [tx, sy, 0.5, token.height]
            pcursor = token.positions[i] - 1
            # puts "setting cursor #{sy}"

          elsif selector.geom? && selector.geom.clicked(tx + (w/2.0), by, (w/2.0), token.height)
            # puts "geom click 2"
            cursor = [tx + w, sy, 0.5, token.height]
            pcursor = token.positions[i]
          end
          
          tx += w
        end

        if !x.nil?
          ay = cy + padding.top - selector.offset_y
          yield Hokusai::Rect.new(x, ay, tw, token.height)

          tw = 0.0
        end
      end

      selector.pos.cursor_index = pcursor
      selector.pos.positions = position_buffer
      selector.geom.cursor = cursor

      WrapCachePayload.new(copy_buffer, position_buffer, pcursor)
    end

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

  # A disposable streaming text wrapper
  # tokens can be appended onto it, where it they will break on a given width.
  # Opaque payloads can be passed for each token, which will be provided to callbacks.
  # This makes it suitable for processing and wrapping markdown/html/tokenized text
  #
  # height of the wrapped text is tracked with `stream#y`
  class WrapStream
    attr_accessor :buffer, :x, :y, :origin_y, :current_width, :stack, :widths, :current_position, :positions, :on_text_cb
    attr_reader :width, :origin_x, :on_text_cb

    def initialize(width, origin_x = 0.0, origin_y = 0.0, &measure)
      @width = width            # the width of the container for this wrap
      @measure_cb = measure     # a measure callback that returns the width/height of a given char (takes 2 params: a char and an token payload)
      @on_text_cb = ->(_) {}    # a callback that receives a wrapped token for a given line.  (takes a Hokusai::Util::Wrapped paramter)

      @origin_x = origin_x      # the origin x coordinate, x will reset to this
      @x = origin_x             # the marker for x coord, this is used to track against the width of a given line
      @y = origin_y             # the marker for the y coord, this grows by <size> for each line, resulting in the height of the wrapped text
      @current_width = 0.0      # the current width of the buffer
      @stack = []               # a stack storing buffer offsets with their respective token payloads.
      @buffer = ""              # the current buffer that the stack represents.
      
      @current_position = 0     # the current char index
      @positions = []           # a stack of char positions, used for editing
      @widths = []              # a stack of char widths, used later in selection
    end

    NEW_LINE_REGEX = /\n/

    # Appends <text> to the wrap stream.
    # If the text supplies causes the buffer to grow beyond the supplied width
    # The buffer will be flushed to the <on_text_cb> callback.
    #
    # @param [String] text (text to append to this wrap stream)
    # @param [Object] extra (an opaque payload that will be passed to callbacks)
    def wrap(text, extra)
      offset = 0
      size = text.size
      
      # appends the initial stack value for this text
      stack << [((buffer.size)..(text.size + buffer.size - 1)), extra]

      # char-by-char processing.
      while offset < size
        char = text[offset]
        self.current_position = offset

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
            stack << [(0...(text.size - offset)), xtra]
          end
        # append this char does NOT extend beyond the width
        else
          self.current_width += w
          buffer << char
          widths << w
          positions << current_position
        end

        offset += 1
      end
    end

    # Flushes the current buffer/stack.
    def flush
      stack.each do |(range, extra)|
        content = buffer[range]
        size = content.size
        content_width, content_height = measure(content, extra)

        wrap_and_call(content, content_width, content_height, extra)
        self.x += content_width
      end

      self.buffer = ""
      self.current_width = 0.0
      stack.clear
      widths.clear
      positions.clear
      self.x = origin_x
    end

    def on_text(&block)
      @on_text_cb = block
    end

    private

    def wrap_and_call(text, width, height, extra)
      rect = Hokusai::Rect.new(x, y, width, height)
      @on_text_cb.call Wrapped.new(text.dup, rect, extra, widths: widths.dup, positions: positions.dup)
    end

    def measure(string, extra)
      @measure_cb.call(string, extra)
    end
  end
end
