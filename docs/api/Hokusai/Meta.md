---
layout: doc
---
# class Meta <Badge type="info" text="public" />
coordinates block children, including updates and event emitting

## #commands <Badge type="warning" text="internal" />

<p>a Hokusai::Commands cache</p>


## #node_count <Badge type="warning" text="internal" />

<p>How many descedants does this node have?</p>
<p>returns Integer</p>


## #get_child?(index) <Badge type="warning" text="internal" />

<p>Gets a child by index</p>

#### Arguments

*  _index_ - the index of the child block (Integer)

### Returns

Returns Hokusai::Block or nil


## #children=(values) <Badge type="warning" text="internal" />

<p>Sets children</p>

#### Arguments

*  _values_ - array of Hokusai::Block

### Returns

Returns nothing


## #<<(child) <Badge type="warning" text="internal" />

<p>Append child</p>

#### Arguments

*  _child_ - a Hokusai::Block


## #get_child(index) <Badge type="warning" text="internal" />

<p>Gets a child by index.  Creates an empty array if no children found.</p>

#### Arguments

*  _index_ - the index of the child block (Integer)

### Returns

Returns Hokusai::Block


## #set_child(index, value) <Badge type="info" text="public" />

<p>Set a child by index. Creates an empty array if no children found.</p>

#### Arguments

*  _index_ - the index of child block (Integer)
*  _value_ - a Hokusai::Block

### Returns

Returns nothing


## #children\! <Badge type="warning" text="internal" />

<p>Returns children or empty array</p>


## #props\! <Badge type="warning" text="internal" />

<p>Returns props or empty hash</p>


## #get_prop?(name) <Badge type="info" text="public" />

<p>Get a prop value by it's name</p>

#### Arguments

*  _name_ - name of prop (Symbol)

### Returns

Returns Object or Nil if no props found


## #set_prop(name, value) <Badge type="info" text="public" />

<p>Set a prop value</p>

#### Arguments

*  _name_ - name of prop (Symbol)
*  _value_ - value to set prop to


## #get_prop(name) <Badge type="info" text="public" />

<p>Get a prop value by it's name</p>

#### Arguments

*  _name_ - name of prop (Symbol)

### Returns

Returns Object or nil if prop not found


## #focus <Badge type="info" text="public" />

<p>Set this node and chlidren to focused</p>


## #blur <Badge type="info" text="public" />

<p>Unfocus this node and children</p>


## #on_update(target, &block) <Badge type="warning" text="internal" />

Set on update callback.  Used by [Hokusai::NodeMounter](/api/Hokusai/NodeMounter) and the like

#### Arguments

*  _target_ - a Hokusai::Block that this node should emit events to
*  _block_ - an updater callback


## #update(value) <Badge type="warning" text="internal" />

<p>Updates the props on (value), calling lifecycle callbacks if they exist.</p>

#### Arguments

*  _value_ - a Hokusai::Block


## #child_delete(index) <Badge type="warning" text="internal" />

<p>Delete a child by index, calling lifecycle callbacks if they exist.</p>

#### Arguments

*  _index_ - the index of the child

### Returns

Returns nothing


