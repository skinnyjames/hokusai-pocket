---
layout: doc
---
# module Hokusai 


## .docker_template <Badge type="warning" text="internal" />

<p>Docker templates that get written to disk by binary</p>
<p>during cross platform publishing</p>


## .fonts <Badge type="info" text="public" />

<p>Access the font registry</p>

### Returns

Returns a [Hokusai::FontRegistry](/api/Hokusai/FontRegistry)


## .textures <Badge type="info" text="public" />

<p>Access the texture registry</p>

### Returns

Returns a [Hokusai::TextureRegistry](/api/Hokusai/TextureRegistry)


## .images <Badge type="info" text="public" />

<p>Access the image registry</p>

### Returns

Returns a [Hokusai::ImageRegistry](/api/Hokusai/ImageRegistry)


## .musics <Badge type="info" text="public" />

<p>Access the music registry</p>

### Returns

Returns a [Hokusai::MusicRegistry](/api/Hokusai/MusicRegistry)


## .close_window <Badge type="info" text="public" />

<p>close the current window</p>

### Returns

Returns nothing


## .restore_window <Badge type="info" text="public" />

<p>Restores the current window</p>

### Returns

Returns nothing


## .minimize_window <Badge type="info" text="public" />

<p>Minimizes the current window</p>

### Returns

Returns nothing


## .maximize_window <Badge type="info" text="public" />

<p>Maxmizes the current window</p>

### Returns

Returns nothing


## .set_window_position(x, y) <Badge type="info" text="public" />

<p>Sets the window position on the screen</p>

#### Arguments

*  _x_ - the screen's x coordinate
*  _y_ - the screen's y coordinate

### Returns

Returns nothing


## .set_mouse_position(mouse) <Badge type="info" text="public" />

<p>Sets the mouse position</p>

#### Arguments

*  _mouse_ - a Hokusai::Mouse with the position set.


## .open_file(hash) <Badge type="info" text="public" />

<p>Picks a file path to open using native file dialog</p>

#### Arguments

*  _hash_ - options for native file dialog
   * :filter - A comma delimited string of extensions to filter

### Examples

```ruby
if path = Hokusai.open_file(filter: "png,jpg,jpeg,gif")
  p File.read(path)
end
```


## .save_file(hash) <Badge type="info" text="public" />

<p>Picks a file path to save using native file dialog</p>

#### Arguments

*  _hash_ - options for native file dialog
   * :filter - A comma delimited string of extensions to filter

### Examples

```ruby
if path = Hokusai.save_file(filter: "txt,md")
  File.open(path, "w") { |io| io << "Hello" }
end
```

### Returns

Returns nothing


## .can_render(canvas) <Badge type="info" text="public" />

<p>Tells if a canvas is renderable (useful for pruning unneeded renders)</p>

#### Arguments

*  _canvas_ - a Hokusai::Canvas

### Returns

Returns a boolean


## .set_mouse_cursor(type) <Badge type="info" text="public" />

<p>Sets the mouse cursor from the available types:</p>

#### Arguments

*  _type_ - A symbol representing the type. can be one of [:default, :arrow, :ibeam, :crosshair, :pointer, :none]


## .copy(text) <Badge type="info" text="public" />

<p>Copies text to clipboard</p>

#### Arguments

*  _text_ - the text to copy (String)

### Returns

Returns nothing


## .copy_state <Badge type="warning" text="internal" />

<p>Copies state from one Hokusai::Block to another Hokusai::Block</p>
<p>Used in hot reloading to preserve state between reloads</p>
<p>You probably don't need this</p>


