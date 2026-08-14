---
layout: doc
---
# class Image < Commands::Base <Badge type="warning" text="internal" />
Command to render an Hokusai::Image

## #initialize(image, x, y, width, height) <Badge type="warning" text="internal" />

<p>constructor</p>

#### Arguments

*  _image_ - a Hokusai::Image
*  _x_ - x coordinate
*  _y_ - y coordinate
*  _width_ - width (float)
*  _height_ - height (float)


## #slice=(rect) <Badge type="info" text="public" />

<p>Specify a slice of the image to render</p>
<p>        Useful for spritesheets</p>

#### Arguments

*  _rect_ - a [Hokusai::Rect](/api/Hokusai/Rect) which denotes where to pick from the image

### Returns

Returns nothing


