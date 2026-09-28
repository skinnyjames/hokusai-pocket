---
layout: doc
---
# class PositionSelection <Badge type="info" text="public" />
Represents a selectable area using offsets. Designed for text/char selection.
Used from with [Util::Selection](/api/Hokusai/Util/Selection)
Depends on Util::GeometrySelection and also [Hokusai::Util::Wrapped](/api/Hokusai/Util/Wrapped)

## #cursor_index=(index) <Badge type="info" text="public" />

<p>get/set the cursor offset</p>

#### Arguments

*  _index_ - an integer representing the current offset

### Returns

Returns the cursor ofset


## #positions=(range) <Badge type="info" text="public" />

<p>get/set the selected positions</p>

#### Arguments

*  _range_ - a range denoting the start..end selection

### Returns

Returns the positions


## #move(to, selecting) <Badge type="info" text="public" />

<p>Moves cursor to (index)</p>

#### Arguments

*  _to_ - the offset to move the cursor to
*  _selecting_ - a boolean to denote that the move should adjust the selectable region

### Returns

Returns nothing


## #frozen? <Badge type="info" text="public" />

<p>Is this selection frozen?</p>

### Returns

Returns boolean


## #freeze\! <Badge type="info" text="public" />

<p>Freeze the selection to prevent modifications</p>


## #concat(arr) <Badge type="info" text="public" />

<p>merges the geometry selection into the existing positions</p>

#### Arguments

*  _arr_ - the tokens: _Array(Hokusai::Util::Wrapped)_ that are currently selected on the screen. Note: if the selection is out of the viewport, this will be missing tokens.

### Returns

Returns nothing


## #selected(offset) <Badge type="info" text="public" />

<p>Is this offset selected?</p>

#### Arguments

*  _offset_ - An index (Integer) to test

### Returns

Returns boolean


## #clear <Badge type="info" text="public" />

<p>Reset this selection</p>

### Returns

Returns nothing


## #cursor_index=(index) <Badge type="info" text="public" />

<p>get/set the cursor offset</p>

#### Arguments

*  _index_ - an integer representing the current offset

### Returns

Returns the cursor ofset


## #positions=(range) <Badge type="info" text="public" />

<p>get/set the selected positions</p>

#### Arguments

*  _range_ - a range denoting the start..end selection

### Returns

Returns the positions


## #move(to, selecting) <Badge type="info" text="public" />

<p>Moves cursor to (index)</p>

#### Arguments

*  _to_ - the offset to move the cursor to
*  _selecting_ - a boolean to denote that the move should adjust the selectable region

### Returns

Returns nothing


## #frozen? <Badge type="info" text="public" />

<p>Is this selection frozen?</p>

### Returns

Returns boolean


## #freeze\! <Badge type="info" text="public" />

<p>Freeze the selection to prevent modifications</p>


## #concat(arr) <Badge type="info" text="public" />

<p>merges the geometry selection into the existing positions</p>

#### Arguments

*  _arr_ - the tokens: _Array(Hokusai::Util::Wrapped)_ that are currently selected on the screen. Note: if the selection is out of the viewport, this will be missing tokens.

### Returns

Returns nothing


## #selected(offset) <Badge type="info" text="public" />

<p>Is this offset selected?</p>

#### Arguments

*  _offset_ - An index (Integer) to test

### Returns

Returns boolean


## #clear <Badge type="info" text="public" />

<p>Reset this selection</p>

### Returns

Returns nothing


