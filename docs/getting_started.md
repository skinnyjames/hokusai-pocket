---
next:
  text: Application Anatomy
  link: /anatomy.md
---
# Getting started

## Installation

The easiest way to get started with hokusai-pocket is to download the binary from the [releases](https://github.com/skinnyjames/hokusai-pocket/releases) page.
The binary can run or publish applications, as well as rebuild itself with different configurations.

## Building from source

To build the hokusai-pocket binary from source, first you'll need a copy of [barista](https://github.com/skinnyjames/mruby-bin-barista/releases/tag/0.3.1) for
your platform.

Then, in this source directory, run: `barista @desktop` to build a copy of `hokusai-pocket` for your host system.
The binary will be located in `bin`

The build can be customized.

## Running your first program

Let's try it out with an application.  Open a new file at `counter.rb`, and paste the following code.

```ruby
# counter.rb
class Counter < Hokusai::Block
 template <<-EOF
 [template]
   hblock
     label {
       size="190"
       :content="count.to_s"
       :color="count_color"
     }
   hblock
     vblock { @click="increment" :background="BLUE"}
       label { content="Add" }
     vblock { @click="decrement":background="RED" }
       label { content="Subtract" }
 EOF

 uses(
   vblock: Hokusai::Blocks::Vblock,
   hblock: Hokusai::Blocks::Hblock,
   label: Hokusai::Blocks::Text,
 )

  RED = [244, 0, 0]
  BLUE = [0, 0, 244]

  attr_accessor :count

  def count_positive = count > 0
  def increment(event) = self.count += 1
  def decrement(event) = self.count -= 1
  def count_color = count.negative? ? RED : BLUE

  def initialize(**args)
    @count = 0

    super
  end
end

Hokusai::Backend.run(Counter) do |config|
  config.title          = "Counter"
  config.width          = 550
  config.height         = 500
  config.hot_reload     = "counter.rb"
  config.event_waiting  = false
  config.after_load do
    Hokusai.fonts.register "default", Hokusai::Backend::Font.default
    Hokusai.fonts.activate "default"
  end
end
```

Now, you can use the binary to run this program.
* `hokusai-pocket run:target=counter.rb`

You should see something like

<video controls>
  <source src="./images/counter.mp4">
</video>

Since we configured the application to use hot reloading, you can also edit the app and it will update in real time.

