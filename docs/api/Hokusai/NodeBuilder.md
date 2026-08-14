---
layout: doc
---
# class NodeBuilder <Badge type="info" text="public" />
Template DSL used in [Hokusai::Block.template](/api/Hokusai/Block.html#template-template-block)

## .build(name, &block) <Badge type="info" text="public" />

<p>Builds an AST using a DSL</p>

#### Arguments

*  _name_ - a Hokusai::Block.class
*  _block_ - a DSL callback to build this AST


## #merge_styles(names) <Badge type="info" text="public" />

<p>Merge style defintions into this template</p>

#### Arguments

*  _names_ - a splatted array of style names (*names)

### Returns

Returns nothing


## #static(name, value, Examples:) <Badge type="info" text="public" />

<p>Declares a static prop</p>

#### Arguments

*  _name_ - the prop key (Symbol)
*  _value_ - a String containing the static prop value
*  _Examples:_ - static :size, "10" static :content, "'string'"

### Returns

Returns nothing


## #prop(name, value, &block) <Badge type="info" text="public" />

<p>declare a prop value.</p>
<p>        evaluates in the context of the Hokusai::Block</p>

#### Arguments

*  _name_ - the prop name (Symbol)
*  _value_ - a prop value (required if &block is nil)
*  _block_ - a callback that returns the prop value

### Returns

Returns nothing


## #show_if(method, &block) <Badge type="info" text="public" />

<p>conditionally render this node if the provided method evaluates to true</p>

#### Arguments

*  _method_ - name of a method on the calling Hokusai::Block (optional if passing block)
*  _block_ - callback that should evaluate to a boolean (optional if passing method)

### Returns

Returns nothing


## #each_child(klass, method, &block) <Badge type="info" text="public" />

<p>defines a loop directive</p>

#### Arguments

*  _klass_ - the Hokusai::Block to use
*  _method_ - a method name (Symbol) that returns an Enumerable
*  _block_ - callback for building this AST node

### Examples

```ruby
class Something < Hokusai::Block
  template do
    child(Hokusai::Blocks::Vblock) do
      each_child(Hokusai::Blocks::Text, :items) do |item|
        prop :key do
          "key-#{item.value}"
        end
        #
        # item is a Hokusai::ProxyValue
        #
        prop :content do
          item.value
        end
      end
    end
  end
  #
  def items
    %w[foo bar baz]
  end
end
```

### Returns

Returns nothing


## #on(event_name, &block) <Badge type="info" text="public" />

<p>Event handler subscription</p>

#### Arguments

*  _event_name_ - name of event (Symbol | String)
*  _block_ - callback that is passed the event parameters as block params

### Examples

```ruby
on :click do |event|
  puts event.pos.x # clicked x coordinate
end
```

### Returns

Returns nothing


## #child(klass, &block) <Badge type="info" text="public" />

<p>declare a child block</p>

#### Arguments

*  _klass_ - a Hokusai::Block
*  _block_ - a callback to build this AST node

### Examples

```ruby
template do
  child(Hokusai::Blocks::Vblock) do
    child(Hokusai::Blocks::Text) do
      #...
    end
  end
end
```

### Returns

Returns nothing


