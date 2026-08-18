---
layout: doc
---
# class Padding <Badge type="info" text="public" />
Hokusai::Padding represents padding around a given geometry

## #initialize(top, right, bottom, left) <Badge type="info" text="public" />

<p>Constructor for Hokusai::Padding</p>

#### Arguments

*  _top_ - top outline width (Float)
*  _right_ - right outline width (Float)
*  _bottom_ - bottom outline width (Float)
*  _left_ - left outline width (Float)

### Returns

Returns Hokusai::Padding


## #width <Badge type="info" text="public" />

<p>The total width of the padding</p>

### Returns

Returns Float


## #height <Badge type="info" text="public" />

<p>The total height of the padding</p>

### Returns

Returns Float


## .convert(value) <Badge type="info" text="public" />

<p>Converts value to padding</p>

#### Arguments

*  _value_ - value can be String of comma delimited float values (top, right, bottom, left) an Array of float values, a Hokusai::Padding value or an Integer, which will be applied to uniformly

### Examples

```ruby
Hokuasi::Padding.convert("22,22,22,22")
# Hokusai::Padding(@top = 22, @right = 22, @bottom = 22, @left = 22)
```

### Returns

Returns Hokusai::Padding


