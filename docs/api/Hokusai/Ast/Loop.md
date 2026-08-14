---
layout: doc
---
# class Loop <Badge type="warning" text="internal" />
Represents a loop node.  Can be made from a string template or 
        using the [Hokusai::NodeBuilder](/api/Hokusai/NodeBuilder) DSL.
        You need to provide a unique key for the looped ast node
        Warning: Loops cannot currently be top level, nest them in another block - see examples.
#### Examples

```ruby
# Make loop from template
#
class Something < Hokusai::Block
  template <<-EOF
  [template]
  vblock
    [for="item in items"]
      text { :key="make_key(item, index)" :content="item" }
  EOF
  #
  # In string templates, the magic "index" variable is available
  # to pass to dynamic prop functions
  def make_key(item, index)
    "key-#{item}-#{index}"
  end
  #
  def items
    %w[foo bar baz]
  end
end
```
```ruby
# Make loop from the NodeBuilder DSL
#
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


