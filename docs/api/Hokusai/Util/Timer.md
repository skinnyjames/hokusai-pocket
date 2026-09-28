---
layout: doc
---
# class Timer <Badge type="info" text="public" />
A timer utility to test for passed time.
         Useful for debounce operations or animations
#### Examples

```ruby
timer = Hokusai::Util::Timer.new
timer.elapsed(1.0) # false
Hokusai.sleep(1.2)
timer.elapsed(1.0) # true
timer.reset
```


## #elapsed(seconds) <Badge type="info" text="public" />

<p>Check for elapsed time</p>

#### Arguments

*  _seconds_ - Number of seconds to check for (Integer)

### Returns

Returns boolean


## #reset <Badge type="info" text="public" />

<p>Reset the timer</p>

### Returns

Returns nothing


