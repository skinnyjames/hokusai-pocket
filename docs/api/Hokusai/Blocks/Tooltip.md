---
layout: doc
---
# class Tooltip < Hokusai::Block <Badge type="info" text="public" />
Spawns a directional tooltip
### Props

* `computed! :label, `
* `computed :direction, default: :down, convert: proc(&:to_sym)
`
* `computed :size, default: 18, convert: proc(&:to_i);`
* `computed :padding, default: Hokusai::Padding.new(2.5, 15.0, 2.5, 15.0), convert: Hokusai::Padding
`
* `computed :color, default: Hokusai::Color.new(22, 22, 22), convert: Hokusai::Color
`
* `computed :background, default: Hokusai::Color.new(222,88,88), convert: Hokusai::Color
`




