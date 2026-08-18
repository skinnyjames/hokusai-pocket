---
layout: doc
---
# class Ast <Badge type="warning" text="internal" />
Represents a template AST.  Can be made from a string template or
using the [Hokusai::NodeBuilder](/api/Hokusai/NodeBuilder) DSL.

## #dump(options) <Badge type="warning" text="internal" />

<p>dumps a string representation of the ast</p>

#### Arguments

*  _options_ - kwargs for modifying the dumped representation (**options)
   * :show_props - show props and events in the dump (default false)

### Returns

Returns a string with the dumped ast


## #has_else_condition? <Badge type="warning" text="internal" />

<p>Does this ast have an else condition?</p>

### Returns

Returns boolean


## #else_condition_active? <Badge type="warning" text="internal" />

<p>Is the else condition on this ast currently active?</p>

### Returns

Returns boolean


## #has_if_condition? <Badge type="warning" text="internal" />

<p>Does this ast have an if condition?</p>

### Returns

Returns boolean


## #loop? <Badge type="warning" text="internal" />

<p>Does this ast have a loop?</p>

### Returns

Returns boolean


## #slot? <Badge type="warning" text="internal" />

<p>Is this ast a slot?</p>

### Returns

Returns boolean


## #virtual? <Badge type="warning" text="internal" />

<p>Is this ast a virtual node?</p>

### Returns

Returns boolean


## #dynamic? <Badge type="warning" text="internal" />

<p>Is this ast made with Hokusai::NodeBuilder?</p>

### Returns

Returns boolean


## #prop(name) <Badge type="warning" text="internal" />

<p>Get a prop by name (if one exists)</p>

#### Arguments

*  _name_ - Name of the prop (String)

### Returns

Returns [Hokusai::Ast::Prop](/api/Hokusai/Ast/Prop) or nil if none exists


## #event(name) <Badge type="warning" text="internal" />

<p>Get a event by name (if one exists)</p>

#### Arguments

*  _name_ - Name of the event

### Returns

Returns [Hokusai::Ast::Event](/api/Hokusai/Ast/Event) or nil if none exists


