---
layout: doc
---
# class BaseEvent <Badge type="warning" text="internal" />
A UI input event used in [Hokusai::Painter](/api/Hokusai/Painter)

## .name(name) <Badge type="warning" text="internal" />

<p>Sets the name of this event kind</p>

#### Arguments

*  _name_ - event name (String)


## #add_evented_styles(value) <Badge type="warning" text="internal" />

<p>adds evented styles to this block</p>

#### Arguments

*  _value_ - a Hokusai::Block


## #add_capture(value) <Badge type="warning" text="internal" />

<p>capture a block</p>

#### Arguments

*  _value_ - a Hokusai::Block


## #stopped <Badge type="warning" text="internal" />

<p>Has the event stopped propagation?</p>

### Returns

Returns boolean


## #stop <Badge type="info" text="public" />

<p>Stop the event from bubbling</p>

### Returns

Returns nothing


## #captures <Badge type="warning" text="internal" />

<p>All captures for this event</p>

### Returns

Returns Array(Hokusai::Block)


## #matches(value) <Badge type="warning" text="internal" />

<p>Does the event match the provided Hokusai::Block template?</p>

#### Arguments

*  _value_ - a Hokusai::Block

### Returns

Returns boolean


## #bubble <Badge type="warning" text="internal" />

<p>Emit the event to all captured blocks,</p>
<p>stopping if any of the blocks stop propagation</p>


