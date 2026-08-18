---
layout: doc
---
# class DropdownItem < Hokusai::Block <Badge type="info" text="public" />
Dropdown item for Hokusai::Blocks::Dropdown
### Props

* `computed! :option, `
* `computed :size, default: 24, convert: proc(&:to_i)
`
* `computed :background, default: [22,22,22], convert: Hokusai::Color
`
* `computed :outline, default: [1.0, 1.0, 1.0, 1.0], convert: Hokusai::Outline
`
* `computed :outline_color, default: [55,55,55], convert: Hokusai::Color
`
* `computed :color, default: [222,222,222], convert: Hokusai::Color
`
* `computed :padding, default: [2.5, 5.0, 2.5, 5.0], convert: Hokusai::Padding
`
* `computed :font, default: nil
`



### Emits

* `emit("picked", option)`




