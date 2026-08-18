---
layout: doc
---
# class Empty < Hokusai::Block <Badge type="info" text="public" />
A block with a virtual node
        useful for collecting events on a block without rendering anything
#### Examples

```ruby
template <<-EOF
[template]
  empty { @click="do_something" }
EOF
```


