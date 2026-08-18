---
layout: doc
---
# class ImageRegistry <Badge type="info" text="public" />
A global registry for storing Hokusai::Image

## #create(name, width, height, transparent) <Badge type="info" text="public" />

<p>create a new image and add it to the registry</p>

#### Arguments

*  _name_ - key for image (String)
*  _width_ - width (Float)
*  _height_ - height (Float)
*  _transparent_ - make the image transparent (default: false)

### Returns

Returns Hokusai::Image


## #register(name, image) <Badge type="info" text="public" />

<p>Registers an image</p>

#### Arguments

*  _name_ - key for image (String)
*  _image_ - a Hokusai::Image

### Returns

Returns nothing


## #get(name) <Badge type="info" text="public" />

<p>Fetches an image from the registry</p>

#### Arguments

*  _name_ - key for image (String)

### Returns

Returns Hokusai::Image


## #delete(name) <Badge type="info" text="public" />

<p>Delete a image from the registry</p>

#### Arguments

*  _name_ - key for image (String)

### Returns

Returns nothing


