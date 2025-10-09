module Hokusai
  # A Backend agnostic font interface
  #
  # Backends are expected to implement the following methods
  class Font
    # Creates a wrapping of text based on container width and font size
    #
    # @param [String] the text to wrap
    # @param [Integer] the font size
    # @param [Float] the width of the container
    # @param [Float] an initital offset
    # @return [Hokusai::Clamping]
    def clamp(text, size, width, initial_offset = 0.0)
      raise Hokusai::Error.new("Font #clamp not implemented")
    end

    # Creates a wrapping of text based on the container width and font size
    # and parses markdown
    # @param [String] the text to wrap
    # @param [Integer] the font size
    # @param [Float] the width of the container
    # @param [Float] an initital offset
    # @return [Hokusai::Clamping]
    def clamp_markdown(text, size, width, initial_offset = 0.0)
      raise Hokusai::Error.new("Font #clamp not implemented")
    end

    # @return [Integer] the font height
    def height
      raise Hokusai::Error.new("Font #height not implemented")
    end
  end

  # A class representing wrapped text
  #
  # A clamping has many segments, delimited by a newline
  # A segment has many possible groups, and a group has many possible charss
  class Clamping
    class Char
      attr_reader :raw

      def initialize(raw)
        @raw = raw
      end

      # @return [Float] the width of the char
      def width
        raw[:width]
      end

      # @return [Integer] the offset of the char relative to the clamping
      def offset
        raw[:offset]
      end
    end

    class Group
      attr_reader :raw

      def initialize(raw)
        @raw = raw
      end

      # @return [Integer] the offset of the group relative to the clamping 
      def offset
        @offset ||= raw[:offset]
      end

      # @return [Integer] number of chars in this group
      def size
        @size ||= raw[:size]
      end

      # @return [Float] the total width of chars in this group
      def width
        chars.sum(&:width)
      end

      # @return [UInt] a flag for this group type
      def type
        @type ||= raw[:type]
      end

      # @return [Bool] is this group normal?
      def normal?
        @normal ||= type == LibHokusai::GROUP_NORMAL
      end

      # @return [Bool] is this group bold?
      def bold?
        @bold ||= ((type & LibHokusai::GROUP_BOLD) != 0)
      end

      # @return [Bool] is this group italics?
      def italics?
        @italics ||= ((type & LibHokusai::GROUP_ITALICS) != 0)
      end

      # @return [Bool] does this group represent a hyperlink?
      def link?
        @link ||= ((type & LibHokusai::GROUP_LINK) != 0)
      end

      # @return [Bool] does this group represent a code block?
      def code?
        @code ||= type & LibHokusai::GROUP_CODE
      end

      # @return [String] the hyperlink for this group if there is one
      def link
        @href ||= raw[:payload].read_string
      end

      # @return [Array<Hokusai::Char>] an array of chars
      def chars
        return @chars unless @chars.nil?

        @chars = []
        each_char do |char|
          @chars << char
        end

        @chars
      end

      def each_char
        char = raw[:chars]
        i = 0

        while !char.null?
          yield Char.new(char), i
          i += 1
          char = char[:next_char]
        end
      end 
    end

    class Segment
      attr_reader :raw

      def initialize(raw)
        @raw = raw
      end

      # A segment width given a range of offsets
      # NOTE: Defaults to the full segment
      def width(range = (offset...offset + size))
        chars[range]&.sum(&:width) || 0.0
      end

      # @return [Integer] the offset of this segment relative to the clamping
      def offset
        raw[:offset]
      end

      # @return [Integer] the number of chars in this segment
      def size
        raw[:size]
      end

      # @return [Array<Hokusai::Char>] an array of chars
      def chars
        return @chars unless @chars.nil?

        @chars = []
        each_char do |char|
          @chars << char
        end

        @chars
      end

      def each_char
        char = raw[:chars]
        i = 0

        while !char.null?
          yield Char.new(char), i
          i += 1
          char = char[:next_char]
        end
      end

      # @return [Array<Hokusai::Group>] an array of clamping groups
      def groups
        return @groups unless @groups.nil?

        @groups = []
        each_group do |group|
          @groups << group
        end

        @groups
      end

      def each_group
        group = raw[:groups]
        i = 0
        until group.null?
          yield Group.new(group), i
          i.succ
          group = group[:next_group]
        end
      end

      def select_end
        raw[:select_end]
      end

      def select_begin
        raw[:select_begin]
      end

      def select_begin=(val)
        raw[:select_begin] = val
      end

      def select_end=(val)
        raw[:select_end] = val.nil? ? select_begin : val
      end

      def has_selection?
        !select_end.nil? && !select_begin.nil?
      end

      def char_is_selected(char)
        return false if select_begin.nil? || select_end.nil? || (select_end - select_begin).zero?

        (select_begin..select_end).include?(char.offset)
      end

      def make_selection(start, stop)
        self.select_begin = start
        self.select_end = stop
      end
    end

    attr_reader :raw, :markdown

    def initialize(raw, markdown: false)
      @markdown = markdown
      @raw = raw
    end

    def segments
      return @segments unless @segments.nil?

      @segments = []
      each_segment do |segment|
        @segments << segment
      end

      @segments
    end

    def debug
      LibHokusai.hoku_text_clamp_debug(raw)
    end

    def each_segment
      segment = raw[:segments]
      i = 0

      until segment.null?
        yield Segment.new(segment), i
        i += 1


        segment = segment[:next_segment]
      end
    end

    def text(segment)
      raw[:text][segment.offset, segment.size]
    end

    def [](offset, size)
      raw[:text][offset, size]
    end

    def to_a
      segments.map do |segment|
        text(segment)
      end
    end
  end

  # Keeps track of any loaded fonts
  class FontRegistry
    attr_reader :fonts, :active_font

    def initialize
      @fonts = {}
      @active_font = nil
    end

    # Registers a font
    #
    # @param [String] the name of the font
    # @param [Hokusai::Font] a font
    def register(name, font)
      raise Hokusai::Error.new("Font #{name} already registered") if fonts[name]

      fonts[name] = font
    end

    # Returns the active font's name
    #
    # @return [String]
    def active_font_name
      raise Hokusai::Error.new("No active font") if active_font.nil?

      active_font
    end

    # Activates a font by name
    #
    # @param [String] the name of the registered font
    def activate(name)
      raise Hokusai::Error.new("Font #{name} is not registered") unless fonts[name]

      @active_font = name
    end

    # Fetches a font
    #
    # @param [String] the name of the registered font
    # @return [Hokusai::Font]
    def get(name)
      fonts[name]
    end

    # Fetches the active font
    #
    # @return [Hokusai::Font]
    def active
      fonts[active_font]
    end
  end
end