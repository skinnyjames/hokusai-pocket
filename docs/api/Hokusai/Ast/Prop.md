---
layout: doc
---
# class Prop <Badge type="warning" text="internal" />
Represents an AST prop
#### Examples

```ruby
# string template usage
node { :prop="func" }
```
```ruby
# builder DSL usage
prop :prop do
  "some-value"
end
```


## #initialize(name, value, computed) <Badge type="warning" text="internal" />

<p>Constructor for the Func</p>

#### Arguments

*  _name_ - the name of the event (String)
*  _value_ - the func value for the event (Hokusai::Func)
*  _computed_ - is this prop computed? (boolean)


## #computed? <Badge type="warning" text="internal" />

<p>Is the prop computed?</p>

### Returns

Returns boolean


