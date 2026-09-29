---
layout: doc
---
# class GeometrySelection <Badge type="info" text="public" />
Represents a selectable area with coordinates.
        Used from with [Util::Selection](/api/Hokusai/Util/Selection)
#### Examples

```ruby
geom = Hokusai::Util::GeometrySelection.new
geom.start(0.0, 0.0)
geom.stop(100.0, 100.0)
geom.down? # true
geom.selected(20.0, 20.0, 20.0, 20.0) # true
```


## #start(x, y) <Badge type="info" text="public" />

<p>Starts a selection</p>

#### Arguments

*  _x_ - the x coordinate selected (Float)
*  _y_ - the y coordinate selected (Float)

### Returns

Returns nothing


## #move_up(height) <Badge type="info" text="public" />

<p>Moves the stop y coordinate up by (height)</p>

#### Arguments

*  _height_ - the amount to move up (Float)

### Returns

Returns nothing


## #move_down(height) <Badge type="info" text="public" />

<p>Moves the stop y coordinate down by (height)</p>

#### Arguments

*  _height_ - the amount to move down (Float)

### Returns

Returns nothing


## #stop(x, y) <Badge type="info" text="public" />

<p>Stops the selection</p>

#### Arguments

*  _x_ - the stop x coordinate (Float)
*  _y_ - the stop y coordinate (Float)

### Returns

Returns nothing


## #up? <Badge type="info" text="public" />

<p>Is the selection going upward?</p>

### Returns

Returns boolean


## #down? <Badge type="info" text="public" />

<p>Is the selection going downward?</p>

### Returns

Returns boolean


## #left? <Badge type="info" text="public" />

<p>Is the selection going left?</p>

### Returns

Returns boolean


## #right? <Badge type="info" text="public" />

<p>Is the selection going right?</p>

### Returns

Returns boolean


## #changed_direction? <Badge type="info" text="public" />

<p>Did the selection change direction?</p>
<p>        (ie: selecting down but now going up)</p>

### Returns

Returns boolean


## #clear <Badge type="info" text="public" />

<p>Resets the selection state</p>

### Returns

Returns nothing


## #clicked(x, y, w, h) <Badge type="info" text="public" />

<p>Is this region clicked?</p>
<p>        Note: need to set `click_pos` to use this.</p>

#### Arguments

*  _x_ - start x of the region (Float)
*  _y_ - start y of the region (Float)
*  _w_ - width of the region (Float)
*  _h_ - height of the region (Float)

### Returns

Returns boolean


## #selected(x, y, w, h) <Badge type="info" text="public" />

<p>Is this region selected?</p>

#### Arguments

*  _x_ - start x of the region (Float)
*  _y_ - start y of the region (Float)
*  _w_ - width of the region (Float)
*  _h_ - height of the region (Float)

### Returns

Returns boolean


## #start(x, y) <Badge type="info" text="public" />

<p>Starts a selection</p>

#### Arguments

*  _x_ - the x coordinate selected (Float)
*  _y_ - the y coordinate selected (Float)

### Returns

Returns nothing


## #move_up(height) <Badge type="info" text="public" />

<p>Moves the stop y coordinate up by (height)</p>

#### Arguments

*  _height_ - the amount to move up (Float)

### Returns

Returns nothing


## #move_down(height) <Badge type="info" text="public" />

<p>Moves the stop y coordinate down by (height)</p>

#### Arguments

*  _height_ - the amount to move down (Float)

### Returns

Returns nothing


## #stop(x, y) <Badge type="info" text="public" />

<p>Stops the selection</p>

#### Arguments

*  _x_ - the stop x coordinate (Float)
*  _y_ - the stop y coordinate (Float)

### Returns

Returns nothing


## #up? <Badge type="info" text="public" />

<p>Is the selection going upward?</p>

### Returns

Returns boolean


## #down? <Badge type="info" text="public" />

<p>Is the selection going downward?</p>

### Returns

Returns boolean


## #left? <Badge type="info" text="public" />

<p>Is the selection going left?</p>

### Returns

Returns boolean


## #right? <Badge type="info" text="public" />

<p>Is the selection going right?</p>

### Returns

Returns boolean


## #changed_direction? <Badge type="info" text="public" />

<p>Did the selection change direction?</p>
<p>        (ie: selecting down but now going up)</p>

### Returns

Returns boolean


## #clear <Badge type="info" text="public" />

<p>Resets the selection state</p>

### Returns

Returns nothing


## #clicked(x, y, w, h) <Badge type="info" text="public" />

<p>Is this region clicked?</p>
<p>        Note: need to set `click_pos` to use this.</p>

#### Arguments

*  _x_ - start x of the region (Float)
*  _y_ - start y of the region (Float)
*  _w_ - width of the region (Float)
*  _h_ - height of the region (Float)

### Returns

Returns boolean


## #selected(x, y, w, h) <Badge type="info" text="public" />

<p>Is this region selected?</p>

#### Arguments

*  _x_ - start x of the region (Float)
*  _y_ - start y of the region (Float)
*  _w_ - width of the region (Float)
*  _h_ - height of the region (Float)

### Returns

Returns boolean


