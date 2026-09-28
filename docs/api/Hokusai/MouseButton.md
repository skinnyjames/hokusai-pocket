---
layout: doc
---
# class MouseButton <Badge type="info" text="public" />
Represenation of mouse button state
#### Examples

```ruby
# from input
input.mouse.left.up # => false
input.mouse.left.down # => true
input.mouse.left.clicked # => true
input.mouse.left.released # => false
input.mouse.left.click_count # => 1
```


## #click_count=(val) <Badge type="info" text="public" />

<p>accessor for click count</p>

#### Arguments

*  _val_ - times this button was clicked

### Returns

Returns 2 for double click, 3 for triple click, etc


