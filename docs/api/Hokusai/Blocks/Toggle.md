---
layout: doc
---
# class Toggle < Hokusai::Block <Badge type="info" text="public" />
toggle for on/off scenarios
### Props

* `computed :size, default: 30.0, convert: proc(&:to_f)
`
* `computed :active_color, default: [137, 126, 186], convert: Hokusai::Color
`
* `computed :inactive_color, default: [61, 57, 81], convert: Hokusai::Color
`
* `computed :color, default: [215, 212, 226], convert: Hokusai::Color
`



### Emits

* `emit("toggle", value: toggled)`




