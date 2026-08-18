---
layout: doc
---
# class Outline 


## #initialize(top, right, bottom, left) <Badge type="info" text="public" />

<p>Constructor for Hokusai::Outline</p>

#### Arguments

*  _top_ - top outline width (Float)
*  _right_ - right outline width (Float)
*  _bottom_ - bottom outline width (Float)
*  _left_ - left outline width (Float)

### Returns

Returns Hokusai::Outline


## .default <Badge type="info" text="public" />

<p>Default outline - zero'ed out.</p>

### Returns

Returns Hokusai::Outline


## .convert(value) <Badge type="info" text="public" />

<p>Converts value to outline</p>

#### Arguments

*  _value_ - value can be String of comma delimited float values (top, right, bottom, left) an Array of float values, a Hokusai::Outline value or an Float, which will be applied to uniformly

### Examples

```ruby
Hokuasi::Outline.convert("1.0,0.0,1.0,0.0")
# Hokusai::Outline(@top = 1.0, @right = 0.0, @bottom = 1.0, @left = 0.0)
```

### Returns

Returns Hokusai::Outline


## #present? <Badge type="info" text="public" />

<p>Does this outline have any widths above 0?</p>

### Returns

Returns boolean


