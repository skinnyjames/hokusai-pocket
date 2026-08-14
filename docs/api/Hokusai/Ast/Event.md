---
layout: doc
---
# class Event <Badge type="warning" text="internal" />
Represents an AST event
#### Examples

```ruby
# string template usage
node { @event="func" }
```
```ruby
# builder DSL usage
on :event do |event|
  #...
end
```


## #initialize(name, value) <Badge type="warning" text="internal" />

<p>Constructor for the Func</p>

#### Arguments

*  _name_ - the name of the event (String)
*  _value_ - the func value for the event (Hokusai::Func)


