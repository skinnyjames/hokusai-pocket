---
layout: doc
---
# class Keyboard <Badge type="warning" text="internal" />
Represents keyboard state
populated by the MRuby/Raylib backend.
Should not need to use this directly.

## #printable? <Badge type="info" text="public" />

<p>Is the pressed key printable?</p>

### Returns

Returns boolean


## #symbol <Badge type="warning" text="internal" />

<p>The symbol form of the pressed key</p>

### Examples

```ruby
keyboard.symbol
#=> :enter
```

### Returns

Returns Symbol


## #code <Badge type="warning" text="internal" />

<p>The integer code form of the pressed key</p>

### Examples

```ruby
keyboard.symbol
#=> 257
```

### Returns

Returns Symbol


## #char <Badge type="warning" text="internal" />

<p>The char of the presed key</p>

### Returns

Returns String


