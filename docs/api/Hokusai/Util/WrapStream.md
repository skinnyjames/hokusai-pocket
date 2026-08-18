---
layout: doc
---
# class WrapStream <Badge type="info" text="public" />
A disposable streaming text wrapper
        tokens can be appended onto it, where it they will break on a given width.
        Opaque payloads can be passed for each token, which will be provided to callbacks.
        This makes it suitable for processing and wrapping markdown/html/tokenized text
#### Examples

```ruby
stream = Hokusai::Util::WrapStream.new(canvas.width, canvas.x, canvas.y) do |string, extra|
  # String is the data being wrapped
  # Extra is the payload provided for that string
  # Callbacks takes a [width, height] as response
  [Hokusai.fonts.get("default").measure(string, size).first, size]
end
#
# subscribe to emitted tokens Hokusai::Util::Wrapped
stream.on_text do |wrapped|
  draw do
    text(wrapped.text, wrapped.x, wrapped.y) do |command|
      command.color = wrapped.extra[:color]
    end
  end
end
# Feed the stream content
stream.wrap("Hello this red text might be wrapped over the width", { color: Hokusai::Color.new(222,22,22) })
stream.wrap("This is blue text", { color: Hokusai::Color.new(22,22,222) })
# flush remaining tokens
stream.flush
# stream#y now holds the total height of the wrapped tokens
stream.y
```


## #initialize(width, origin_x, origin_y, &block) <Badge type="info" text="public" />

<p>constructor for WrapStream</p>

#### Arguments

*  _width_ - a float. When text exceeds this width, it will wrap to a new line
*  _origin_x_ - where the x value starts (default: 0.0)
*  _origin_y_ - where the y value starts (default: 0.0)
*  _block_ - a callback to measure a given string. Callback must return an array containing the width and height of the string


## #wrap(text, extra) <Badge type="info" text="public" />

<p>Appends (text) to the wrap stream.</p>
<p>        If the text supplies causes the buffer to grow beyond the supplied width</p>
<p>        The buffer will be flushed to the (on_text_cb) callback.</p>

#### Arguments

*  _text_ - text to append to this wrap stream
*  _extra_ - an opaque payload that will be passed to callbacks

### Returns

Returns nothing


## #flush <Badge type="info" text="public" />

<p>Flushes the current buffer/stack.</p>


## #on_text(&block) <Badge type="info" text="public" />

<p>A callback that is called whenever the stream is wrapped or flushes</p>

#### Arguments

*  _block_ - the provided callback

### Returns

Returns nothing


