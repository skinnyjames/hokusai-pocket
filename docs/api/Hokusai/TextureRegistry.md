---
layout: doc
---
# class TextureRegistry <Badge type="info" text="public" />
A global registry for storing Hokusai::Texture

## #create(name, width, height) <Badge type="info" text="public" />

<p>create a new texture and add it to the registry</p>

#### Arguments

*  _name_ - key for texture (String)
*  _width_ - width (Float)
*  _height_ - height (Float)

### Returns

Returns Hokusai::Texture


## #register(name, texture) <Badge type="info" text="public" />

<p>Registers a texture</p>

#### Arguments

*  _name_ - key for texture (String)
*  _texture_ - a Hokusai::Texture

### Returns

Returns nothing


## #get(name) <Badge type="info" text="public" />

<p>Fetches a texture from the registry</p>

#### Arguments

*  _name_ - key for texture (String)

### Returns

Returns Hokusai::Texture


## #delete(name) <Badge type="info" text="public" />

<p>Delete a texture from the registry</p>

#### Arguments

*  _name_ - key for texture (String)

### Returns

Returns nothing


