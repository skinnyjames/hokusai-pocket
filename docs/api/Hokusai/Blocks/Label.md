---
layout: doc
---
# class Label < Hokusai::Block <Badge type="info" text="public" />
A simple label that changes node size according to text size
### Props

* `computed! :content, `
* `computed :font, default: nil
`
* `computed :size, default: 12
`
* `computed :color, default: [33,33,33], convert: Hokusai::Color
`
* `computed :padding, default: [5.0, 5.0, 5.0, 5.0], convert: Hokusai::Padding
`



### Emits

* `emit("width_updated", width + padding.right + padding.left)`




