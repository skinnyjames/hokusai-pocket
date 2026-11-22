---
layout: doc
---
# class Work <Badge type="info" text="public" />
Class for handling async work.
        Queues work on the default libuv loop
#### Examples

```ruby
Hokusai::Work.register :some_job do |state|
  state.times do |i|
    p i
  end
```
```ruby
  :done
end
```
```ruby
Hokusai::Work.queue :some_job, 20000 do |result|
  p result # :done
end
```


