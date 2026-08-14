---
layout: doc
---
# class Node <Badge type="warning" text="internal" />
Container for the AST, props, events, and children
available on [Hokusai::Block#node](/api/Hokusai/Block#node)

## #slot? <Badge type="warning" text="internal" />

<p>Is this node a slot?</p>

### Returns

Returns boolean


## #type <Badge type="warning" text="internal" />

<p>name of this node</p>

### Returns

Returns String


## #event(name) <Badge type="warning" text="internal" />

<p>Get a event by name (if one exists)</p>

#### Arguments

*  _name_ - Name of the event

### Returns

Returns [Hokusai::Ast::Event](/api/Hokusai/Ast/Event) or nil if none exists


## #emit <Badge type="warning" text="internal" />

<p>Emit event to subscribers</p>


