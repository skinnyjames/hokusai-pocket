---
layout: doc
---
# class Func <Badge type="warning" text="internal" />
Represents an AST event or dynamic prop value
#### Examples

```ruby
node { @click="func" }
```
```ruby
# Computed props can take loop args
node { :prop="func(arg, index)" }
```


## #initialize(method, args) <Badge type="warning" text="internal" />

<p>Constructor for Func</p>

#### Arguments

*  _method_ - the name of the func or a proc that the func evaluates to (String | Proc)
*  _args_ - an array of argument names (String) for the func


## #proc? <Badge type="warning" text="internal" />

<p>Is the func made with Hokusai::NodeBuilder?</p>

### Returns

Returns boolean


