---
layout: doc
---
# class Button < Hokusai::Block <Badge type="danger" text="deprecated" />
A crappy button implmentation
### Props

* `computed :padding, default: [5.0, 15.0, 5.0, 15.0], convert: Hokusai::Padding
`
* `computed :size, default: 24
`
* `computed :rounding, default: 0.5
`
* `computed :content, default: ""
`
* `computed :outline, default: 0.0, convert: Hokusai::Outline
`
* `computed :outline_color, default: nil, convert: Hokusai::Color
`
* `computed :background, default: DEFAULT_BACKGROUND, convert: Hokusai::Color
`
* `computed :hovered_background, default: DEFAULT_HOVERED_BACKGROUND, convert: Hokusai::Color
`
* `computed :clicked_background, default: DEFAULT_CLICKED_BACKGROUND, convert: Hokusai::Color
`
* `computed :color, default: [215, 213, 226], convert: Hokusai::Color
`



### Emits

* `emit("clicked", event)`




