module Hokusai
  class MusicRegistry
    def initialize
      @musics = {}
    end

    def register(name, music)
      @musics[name] = music
    end

    def get(name)
      @musics[name]
    end

    def delete(name)
      @musics.delete(name)
    end
  end

  class TextureRegistry
    attr_reader :textures

    def initialize
      @textures = {}
    end

    def create(name, width, height)
      @textures[name] ||= Hokusai::Texture.init(width, height)
      @textures[name]
    end

    def register(name, texture)
      @textures[name] = texture
    end

    def get(name)
      @textures[name]
    end

    def delete(name)
      @textures.delete(name)
    end
  end

  class ImageRegistry
    def initialize
      @images = {}
    end

    def create(name, width, height, transparent = false)
      @images[name] ||= Hokusai::Image.init(width, height, transparent)
      @images[name]
    end

    def register(name, image)
      @images[name] = image
    end

    def get(name)
      @images[name]
    end

    def delete(name)
      @images.delete(name)
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