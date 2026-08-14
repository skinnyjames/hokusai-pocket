---
layout: doc
---
# class Commands 


## #rect(x, y, width, height) <Badge type="info" text="public" />

Draw a rectangle.  Yields a [Commands::Rectangle](/api/Hokusai/Commands/Rectangle)

#### Arguments

*  _x_ - the x coordinate
*  _y_ - the y coordinate
*  _width_ - the width of the rectangle
*  _height_ - height of the rectangle


## #circle(x, y, radius) <Badge type="info" text="public" />

Draw a circle.  Yields a [Commands::Circle](/api/Hokusai/Commands/Circle)

#### Arguments

*  _x_ - x coordinate (Float)
*  _y_ - y coordinate (Float)
*  _radius_ - radius of the circle (Float)


## #image(image, x, y, width, height) <Badge type="info" text="public" />

Draws an image.  Yields a [Commands::Image](/api/Hokusai/Commands/Image)

#### Arguments

*  _image_ - a Hokusai::Image
*  _x_ - x coordinate (Float)
*  _y_ - y coordinate (Float)
*  _width_ - width (Float)
*  _height_ - height (Float)


## #scissor_begin(x, y, width, height) <Badge type="info" text="public" />

<p>Starts a scissor region</p>

#### Arguments

*  _x_ - x coordinate (Float)
*  _y_ - y coordinate (Float)
*  _width_ - width (Float)
*  _height_ - height (Float)


## #scissor_end <Badge type="info" text="public" />

<p>ends scissor region</p>


## #blend_mode_begin(type) <Badge type="info" text="public" />

<p>starts blend mode</p>

#### Arguments

*  _type_ - one of the values [:alpha, :multiply, :additive, :colors]


## #blend_mode_end <Badge type="info" text="public" />

<p>ends blend mode</p>


## #shader_begin <Badge type="info" text="public" />

starts a GLSL shader.  Yields a [Commands::ShaderBegin](/api/Hokusai/Commands/ShaderBegin)


## #shader_end <Badge type="info" text="public" />

<p>ends a shader</p>


## #rotation_begin(x, y, deg) <Badge type="info" text="public" />

<p>starts a rotation</p>

#### Arguments

*  _x_ - x coordinate (Float)
*  _y_ - y coordinate (Float)
*  _deg_ - degress to rotate (Integer)


## #rotation_end <Badge type="info" text="public" />

<p>ends a rotation</p>


## #scale_begin <Badge type="info" text="public" />

<p>starts a scale command</p>


## #scale_end <Badge type="info" text="public" />

<p>ends scaling</p>


## #translation_begin(x, y) <Badge type="info" text="public" />

<p>Starts a 2D translation</p>

#### Arguments

*  _x_ - x coordinate (Float)
*  _y_ - y coordinate (Float)


## #translation_end <Badge type="info" text="public" />

<p>Ends a 2D translation</p>


## #texture(texture, x, y) <Badge type="info" text="public" />

<p>Draws a texture</p>

#### Arguments

*  _texture_ - A Hokusai::Texture
*  _x_ - x coordinate (Float)
*  _y_ - y coordinate (Float)


## #text(content, x, y) <Badge type="info" text="public" />

Draws text.  Yields a [Commands::Text](/api/Hokusai/Commands/Text)

#### Arguments

*  _content_ - the text content
*  _x_ - x coord (Float)
*  _y_ - y coord (Float)


