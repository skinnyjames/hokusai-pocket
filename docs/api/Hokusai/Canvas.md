---
layout: doc
---
# class Canvas <Badge type="info" text="public" />
Hokusai::Canvas represents a drawable region
It provides information between Hokusai::Painter and a Hokusai::Block

## #vertical=(value) <Badge type="info" text="public" />

<p>Should the following blocks be vertical?</p>

#### Arguments

*  _value_ - true if vertical

### Returns

Returns Nothing


## #initialize <Badge type="warning" text="internal" />

<p>Constructor for Hokusai::Canvas</p>
<p>You should not need to use this</p>


## #reset(x, y, width, height) <Badge type="info" text="public" />

<p>Resets canvas at [x,y,width, height]</p>

#### Arguments

*  _x_ - x coordinate
*  _y_ - y coordinate
*  _width_ - width of canvas
*  _height_ - height of canvas

### Returns

Returns Nothing


## #to_bounds <Badge type="info" text="public" />

<p>Convert a canvas to a Hokusai::Rect</p>

### Returns

Returns Hokusai::Rect


## #hovered?(input) <Badge type="warning" text="internal" />

<p>Test if Mouse input is hovering this canvas</p>

#### Arguments

*  _input_ - a Hokusai::Input

### Returns

Returns boolean


## #reverse? <Badge type="info" text="public" />

<p>Are the following children of this Canvas reversed?</p>

### Returns

Returns boolean


