---
layout: doc
---
# class Color <Badge type="info" text="public" />
Represents an RGBA color
#### Examples

```ruby
Hokusai::Color.new(0,0,0,255)
# black
```
```ruby
Hokusai::Color.convert([255,0,0,100])
# translucent red
```


## .convert(value) <Badge type="info" text="public" />

<p>Converts value to Hokusai::Color</p>

#### Arguments

*  _value_ - value can be String of comma delimited integer values (red, green, blue, alpha) an Array of integer values, or a Hokusai::Color value

### Examples

```ruby
Hokuasi::Color.convert("22,22,22,22")
# Hokusai::Padding(@red = 22, @green = 22, @blue = 22, @alpha = 22)
```

### Returns

Returns Hokusai::Padding


## #to_shader_value <Badge type="info" text="public" />

<p>Converts to a value where each component is a number between 0 and 1</p>
<p>useful for fragment shaders</p>

### Examples

```ruby
Hokusai::Color.new(255,255,255,255).to_shader_value
# [1.0,1.0,1.0,1.0]
```

### Returns

Returns Array(Float)


