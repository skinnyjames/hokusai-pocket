---
layout: doc
---
# class Scrollbar < Hokusai::Block <Badge type="info" text="public" />
A scrollbar that emits the scroll position
### Props

* `computed :goto, default: nil
`
* `computed :background, default: [22,22,22], convert: Hokusai::Color
`
* `computed :control_color, default: [66,66,66], convert: Hokusai::Color
`
* `computed :control_height, default: 20.0, convert: proc(&:to_f)
`
* `computed :control_rounding, default: 0.75, convert: proc(&:to_f)
`
* `computed :control_padding, default: 2.0, convert: proc(&:to_f)
`



### Emits

* `emit("scroll", scroll_y, percent: percent_scrolled, manual: manual)`




