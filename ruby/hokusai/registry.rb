module Hokusai
  # Public: A global registry for storing Hokusai::Music
  class MusicRegistry
    def initialize
      @musics = {}
    end

    # Public: Registers a Hokusai::Music on (name)
    # 
    # name - key to reference this music (String)
    # music - a Hokusai::Music instance
    def register(name, music)
      @musics[name] = music
    end

    # Public: fetches a music by name
    # 
    # name - key that references a Hokusai::Music
    # 
    # Returns Hokusai::Music
    def get(name)
      @musics[name]
    end

    # Public: delete a music by name
    # 
    # name - key that references a Hokusai::Music
    def delete(name)
      @musics.delete(name)
    end
  end

  # Public: A global registry for storing Hokusai::Texture
  class TextureRegistry
    attr_reader :textures

    def initialize
      @textures = {}
    end

    # Public: create a new texture and add it to the registry
    # 
    # name - key for texture (String)
    # width - width (Float)
    # height - height (Float)
    # 
    # Returns Hokusai::Texture
    def create(name, width, height)
      @textures[name] ||= Hokusai::Texture.init(width, height)
      @textures[name]
    end

    # Public: Registers a texture
    # 
    # name - key for texture (String)
    # texture - a Hokusai::Texture
    # 
    # Returns nothing
    def register(name, texture)
      @textures[name] = texture
    end

    # Public: Fetches a texture from the registry
    # 
    # name - key for texture (String)
    # 
    # Returns Hokusai::Texture
    def get(name)
      @textures[name]
    end

    # Public: Delete a texture from the registry
    # 
    # name - key for texture (String)
    # 
    # Returns nothing
    def delete(name)
      @textures.delete(name)
    end
  end

  # Public: A global registry for storing Hokusai::Image
  class ImageRegistry
    def initialize
      @images = {}
    end

    # Public: create a new image and add it to the registry
    # 
    # name - key for image (String)
    # width - width (Float)
    # height - height (Float)
    # transparent - make the image transparent (default: false)
    # 
    # Returns Hokusai::Image
    def create(name, width, height, transparent = false)
      @images[name] ||= Hokusai::Image.init(width, height, transparent)
      @images[name]
    end

    # Public: Registers an image
    # 
    # name - key for image (String)
    # image - a Hokusai::Image
    # 
    # Returns nothing
    def register(name, image)
      @images[name] = image
    end

    # Public: Fetches an image from the registry
    # 
    # name - key for image (String)
    # 
    # Returns Hokusai::Image
    def get(name)
      @images[name]
    end

    # Public: Delete a image from the registry
    # 
    # name - key for image (String)
    # 
    # Returns nothing
    def delete(name)
      @images.delete(name)
    end
  end

  # Public: A global registry for storing Hokusai::Backend::Font
  class FontRegistry
    attr_reader :fonts, :active_font

    def initialize
      @fonts = {}
      @active_font = nil
    end

    # Public: Registers a font
    #
    # name - font name
    # font - a Hokusai::Backend::Font
    def register(name, font)
      raise Hokusai::Error.new("Font #{name} already registered") if fonts[name]

      fonts[name] = font
    end

    # Public: Returns the active font's name
    #
    # Returns String
    def active_font_name
      raise Hokusai::Error.new("No active font") if active_font.nil?

      active_font
    end

    # Public: Activates a font by name
    #
    # name - the font name
    # 
    def activate(name)
      raise Hokusai::Error.new("Font #{name} is not registered") unless fonts[name]

      @active_font = name
    end

    # Public: Fetches a font
    #
    # name - the name of the registered font
    # 
    # Returns Hokusai::Backend::Font or nil
    def get(name)
      fonts[name]
    end

    # Public: Fetches the active font
    #
    # Returns a Hokusai::Backend::Font or nil
    def active
      fonts[active_font]
    end
  end
end