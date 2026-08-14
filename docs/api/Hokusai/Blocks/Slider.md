---
layout: doc
---
# class Slider < Hokusai::Block 

### Props

* `computed :fill, default: [61,171,211], convert: Hokusai::Color
`
* `computed :background, default: [33,33,33], convert: Hokusai::Color
`
* `computed :circle_color, default: [244,244,244], convert: Hokusai::Color
`
* `computed :initial, default: 0, convert: proc(&:to_i)
`
* `computed :size, default: 20.0, convert: proc(&:to_f)
`
* `computed :step, default: 20, convert: proc(&:to_i)
`
* `computed :min, default: 0, convert: proc(&:to_i)
`
* `computed :max, default: 100, convert: proc(&:to_i)
`
* `computed :padding, default: [10.0, 10.0, 0.0, 10.0], convert: Hokusai::Padding
`



### Emits

* `emit("change", steps_val[index])`




