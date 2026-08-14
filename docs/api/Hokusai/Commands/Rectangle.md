---
layout: doc
---
# class Rectangle < Commands::Base <Badge type="warning" text="internal" />
Command to render a rectangle

## #padding=(value) <Badge type="info" text="public" />

<p>Sets padding for the rectangle</p>

#### Arguments

*  _value_ - a [Hokusai::Padding](/api/Hokusai/Padding) object

### Returns

Returns self


## #outline=(value) <Badge type="info" text="public" />

<p>Set outline for rect</p>

#### Arguments

*  _value_ - a [Hokusai::Outline](/api/Hokusai/Outline) object


## #outline_color=(value) <Badge type="info" text="public" />

<p>Set outline color</p>

#### Arguments

*  _value_ - a [Hokusai::Color](/api/Hokusai/Color) object


## #color=(value) <Badge type="info" text="public" />

<p>Set fill color</p>

#### Arguments

*  _value_ - a [Hokusai::Color](/api/Hokusai/Color) object

### Returns

Returns self


## #round=(amount) <Badge type="info" text="public" />

<p>sets rounding</p>

#### Arguments

*  _amount_ - a float value between 0 and 1

### Returns

Returns self


## #padding? <Badge type="info" text="public" />

<p>returns true if the rectangle has any padding</p>


## #background_boundary <Badge type="info" text="public" />

<p>get the rect dimensions after padding and outline applied</p>

### Returns

Returns Array(Float)


## #outline? <Badge type="info" text="public" />

<p>Does this rect have any outlines?</p>


## #outline_uniform? <Badge type="info" text="public" />

<p>Is the rect outline uniform?</p>


