---
layout: doc
---
# class Dropdown < Hokusai::Block <Badge type="info" text="public" />
A dropdown menu.  takes the prop :options which is an array of strings
or an array of objects which respond to :value
### Props

* `computed! :options, `
* `computed :truncate, default: -1, convert: proc(&:to_i)
`
* `computed :size, default: 24, convert: proc(&:to_i)
`
* `computed :background, default: [22,22,22], convert: Hokusai::Color
`
* `computed :color, default: [222,222,222], convert: Hokusai::Color
`
* `computed :panel_height, default: 300.0, convert: proc(&:to_f)
`
* `computed :direction, default: :down, convert: proc(&:to_sym)
`



### Emits

* `emit("change", active)`




