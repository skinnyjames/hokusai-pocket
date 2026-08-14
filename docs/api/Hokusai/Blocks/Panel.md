---
layout: doc
---
# class Panel < Hokusai::Block 
Renders block inside a scrollable panel (slotted)
### Props

* `computed :align, default: "top", convert: proc(&:to_s)
`
* `computed :scroll_goto, default: nil
`
* `computed :scroll_width, default: 14.0, convert: proc(&:to_f)
`
* `computed :scroll_background, default: nil, convert: Hokusai::Color
`
* `computed :scroll_color, default: nil, convert: Hokusai::Color
`
* `computed :background, default: nil, convert: Hokusai::Color
`
* `computed :autoclip, default: true
`



### Emits

* `emit("scroll", y, percent: percent)`




