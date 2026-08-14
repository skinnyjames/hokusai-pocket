---
layout: doc
---
# class Painter <Badge type="warning" text="internal" />
Responsible for iterating through the render tree, event handling, and invoking the draw callbacks
Used by the C/MRuby backend

## #render(canvas, resize, capture:) <Badge type="warning" text="internal" />

<p>Render the block on this painter in (canvas)</p>

#### Arguments

*  _canvas_ - a Hokusai::Canvas to render on
*  _resize_ - boolean telling us if this frame is resized
*  _capture:_ - kwarg telling us if we should capture events

### Returns

Returns nothing


