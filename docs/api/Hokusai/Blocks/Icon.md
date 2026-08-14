---
layout: doc
---
# class Icon < Hokusai::Block <Badge type="danger" text="deprecated" />
Renders an icon
### Props

* `computed! :type, `
* `computed :size, default: 15, convert: proc(&:to_i)
`
* `computed :color, default: Hokusai::Color.new(0, 0, 0), convert: Hokusai::Color
`
* `computed :background, default: Hokusai::Color.new(255, 255, 255, 0), convert: Hokusai::Color
`
* `computed :outline, default: Hokusai::Outline.default, convert: Hokusai::Outline
`
* `computed :outline_color, default: Hokusai::Color.new(0, 0, 0, 0), convert: Hokusai::Color
`
* `computed :padding, default: Hokusai::Padding.new(2.5, 5.0, 2.5, 5.0), convert: Hokusai::Padding
`
* `computed :center, default: true
`




