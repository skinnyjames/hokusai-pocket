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
* `computed :scroll_wheel_speed, default: 10.0, convert: proc(&:to_f)
`
* `computed :scroll_width, default: 14.0, convert: proc(&:to_f)
`
* `computed :scroll_background, default: nil, convert: Hokusai::Color
`
* `computed :scroll_color, default: nil, convert: Hokusai::Color
`
* `computed :scroll_page_buffer, default: 2.0, convert: proc(&:to_f)
`
* `computed :background, default: nil, convert: Hokusai::Color
`
* `computed :autoclip, default: true
`
* `computed :autoscroll, default: true
`



### Emits

* `emit("scroll", y, percent: percent)`




