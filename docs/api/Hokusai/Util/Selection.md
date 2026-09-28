---
layout: doc
---
# class Selection <Badge type="info" text="public" />
A utility to help coordinate selections.
Currently used for text selection and in [Hokusai::Blocks::Selectable](/api/Hokusai/Blocks/Selectable)

## #cursor=(arr) <Badge type="info" text="public" />

<p>Set the current cursor position</p>

#### Arguments

*  _arr_ - an array of 4 floats (start_x, stop_x, cursor_width, cursor_height)

### Returns

Returns nothing


## #offset_y <Badge type="info" text="public" />

<p>Returns the selection y offset</p>

### Returns

Returns a float


## #geom? <Badge type="info" text="public" />

<p>Is the selection in geometry mode?</p>

### Returns

Returns boolean


## #geom\!(clear) <Badge type="info" text="public" />

<p>Use geometry mode</p>

#### Arguments

*  _clear_ - (boolean) should the positions be cleared? (default true)

### Returns

Returns nothing


## #pos? <Badge type="info" text="public" />

<p>Is the selection in positional mode?</p>

### Returns

Returns boolean


## #pos\!(clear) <Badge type="info" text="public" />

<p>Use positional mode</p>

#### Arguments

*  _clear_ - (boolean) should the geometry be cleared? (default false)

### Returns

Returns nothing


## #clear <Badge type="info" text="public" />

<p>Clear all selections and start in geometry mode.</p>

### Returns

Returns nothing


## #selecting? <Badge type="info" text="public" />

<p>Are we actively selecting?</p>

### Returns

Returns boolean


## #cursor=(arr) <Badge type="info" text="public" />

<p>Set the current cursor position</p>

#### Arguments

*  _arr_ - an array of 4 floats (start_x, stop_x, cursor_width, cursor_height)

### Returns

Returns nothing


## #offset_y <Badge type="info" text="public" />

<p>Returns the selection y offset</p>

### Returns

Returns a float


## #geom? <Badge type="info" text="public" />

<p>Is the selection in geometry mode?</p>

### Returns

Returns boolean


## #geom\!(clear) <Badge type="info" text="public" />

<p>Use geometry mode</p>

#### Arguments

*  _clear_ - (boolean) should the positions be cleared? (default true)

### Returns

Returns nothing


## #pos? <Badge type="info" text="public" />

<p>Is the selection in positional mode?</p>

### Returns

Returns boolean


## #pos\!(clear) <Badge type="info" text="public" />

<p>Use positional mode</p>

#### Arguments

*  _clear_ - (boolean) should the geometry be cleared? (default false)

### Returns

Returns nothing


## #clear <Badge type="info" text="public" />

<p>Clear all selections and start in geometry mode.</p>

### Returns

Returns nothing


## #selecting? <Badge type="info" text="public" />

<p>Are we actively selecting?</p>

### Returns

Returns boolean


