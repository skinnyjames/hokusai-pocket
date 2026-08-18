---
prev:
  text: Getting started
  link: /getting_started.md
next: false
---

# Application Anatomy

In our [Counter](/getting_started.html#running-your-first-program) application, we can see that the application is simply a class that inherits from [Hokusai::Block](/api/Hokusai/Block). 

In fact, there is no difference between a component (block) and an application in hokusai. 
This composability means that you could put a functioning terminal emulator inside a photoshop clone, next a spreadsheet program.


## State

Since blocks in Hokusai are plain ruby objects, you can manage state with them.

For the counter, we want to keep track of the current count. An easy way to do this is to put state in the initializer.
```ruby
class Counter < Hokusai::Block
 #....
 attr_accessor :count

 def initialize(**args)
   @count = 0

   super
 end
```
We could also manage this state in other ways as well

```ruby
attr_accessor :count
def count = @count ||= 0
```
Or use a lifecycle hook

```ruby
attr_accessor :count
def on_mounted = @count = 0
```

## Templates

Templates are a bit more complicated.  Internally, Hokusai is basically a machine that continuously generates an ordered list
of __things__ to draw in a window.

If we want to draw a **red circle** in the middle of **blue square**, the instructions might look like this.

  1. Draw a blue rectangle at the top left position (0, 0) and bottom right at (100, 100)
  1. Draw at red circle at position (50, 50) with a radius of 20

Of course, if we drew the red circle first, the blue square would be drawn on top, so we'd never see it.

A Hokusai template declares a tree of blocks.  More specifically for this example, the template declares a tree of words that map to blocks.
The tree is processed **depth-first**, and each time it is processed, it creates an ordered list of draw commands.
When rendering, each block in the tree is given a recommended section of the window to draw in.  The recommended sections are based on some basic layout rules.

For an idea of the rules, imagine a whitespace significant string template.
```
[template]
vblock
 hblock
   first
   vblock
     second
     third
 vblock
   fourth
   fifth
```


Let's say **hblock** creates a container where children are positioned _horizontally_, and  **vblock** creates a container where children are positioned _vertically_

Let's imagine that the default behavior is to:

* render the whole document in the window regardless if it fits.
* clip any excess content
* divide all space equally between children.


So for the document above, it would look something like:


<pre style="font-size: 12px;">
|----------------|-----------------|
|                |                 |
|                |     second      |
|                |                 |
|     first      |-----------------|
|                |                 |
|                |      third      |
|                |                 |
|----------------------------------|
|                                  |
|              fourth              |
|                                  |
|----------------------------------|
|                                  |
|              fifth               |
|                                  |
|----------------------------------|
</pre>
It becomes quite simple to compute the expected position of each child, as the parent already knows the verticality and dimensions of its children.


For instance, imagine adding a width to the first child, and trimming some height from the hblock
```
[template]
root
 hblock {height="20"}
   first {width="20"}
   vblock
     second
     third
 vblock
   fourth
   fifth
```
The resulting children can flex around this, resulting in something like
<pre style="font-size: 12px">
|------------|---------------------|
|            |     second          |
|    first   |---------------------|
|            |      third          |
|----------------------------------|
|                                  |
|                                  |
|              fourth              |
|                                  |
|                                  |
|----------------------------------|
|                                  |
|                                  |
|              fifth               |
|                                  |
|                                  |
|----------------------------------|
</pre>


Earlier I mentioned the template declares a tree of words that map to blocks.  In order to know which words map to which blocks in a string template,
Hokusai provides a `uses` class method. 


```ruby
 # ...
 uses(
   vblock: Hokusai::Blocks::Vblock,
   hblock: Hokusai::Blocks::Hblock,
   label: Hokusai::Blocks::Text,
 )
 # ...
```

### Reserved Template keywords


There are a couple of reserved string template keywords that should not be used with arbitrary blocks.


| name    | purpose                                                                                                                         |
|---------|---------------------------------------------------------------------------------------------------------------------------------|
| `virtual` | meant for marking a template as a no-op, useful for blocks that render themselves using the drawing api                         |
| `slot`    | meant for declaring a child as a slot. Slots allow one to compose reusable blocks that can have different children or behaviors |


## Drawing API

Blocks don't always need to use templates. Hokusai provides an API generating draw commands directly.

Let's say we want to make a block that renders a circle without using any built-in blocks / templates.
```ruby
class Circle < Hokusai::Block
 template <<~EOF
 [template]
   virtual
 EOF

 # Render takes a `Hokusai::Canvas`, processes any draw commands,
 # and yields the canvas to the next block.
 def render(canvas)
   x = canvas.x + (canvas.width / 2)
   y = canvas.y + (canvas.height / 2)

   radius = 5.0

   draw do
     circle(x, y, radius) do |command|
       command.color = Hokusai::Color.new(255, 0, 0)
     end
   end

   yield canvas
 end
end
```


Overloading the `render` method will allow the block to recieve a `Hokusai::Canvas` which contains
the suggested coordinates where that block should draw.


Once inside, we calculate the center of the canvas using it's coordinates.


Then we open the drawing api by calling `#draw`, which exposes a DSL for drawing primitives, like a circle.


Now our `Circle` block can be used from another blocks template.  In short, this block:


* Declares its template as virtual
* Declares a render method
* Calls the draw method inside render and invokes methods for drawing 

A full list of commands can be found [here](/api/Hokusai/Commands).


## Composability


You may have noticed from [Counter](/getting_started.html#running-your-first-program) that the template shows names nested inside each other.


This is because those blocks are _slotted_. A `slot` in Hokusai is placeholder for blocks provided by a parent which is not known.
The blocks that fill the placeholder will be rendered as the children of the block declaring the slot,
but these blocks will still receive props from and emit events to their original parent.


To illustrate, consider the template string for [`Hokusai::Blocks::Panel`](https://github.com/skinnyjames/hokusai-pocket/blob/main/ruby/hokusai/blocks/panel.rb#L2).


```ruby
class Hokusai::Blocks::Panel < Hokusai::Block
template <<~EOF
   [template]
     hblock {
       :background="background"
       @wheel="wheel_handle"
     }
       clipped { :auto="autoclip" :offset="offset" }
         dynamic { @size_updated="set_size" }
           slot
       [if="scroll_active"]
         scrollbar.scroller {
           @scroll="scroll_complete"
           :top="panel_top"
           :goto="scrollbar_goto"
           :width="scroll_width"
           :background="scroll_background"
           :control_color="scroll_color"
           :control_height="scroll_control_height"
         }
 EOF


 uses(
   clipped: Hokusai::Blocks::Clipped,
   dynamic: Hokusai::Blocks::Dynamic,
   hblock: Hokusai::Blocks::Hblock,
   scrollbar: Hokusai::Blocks::Scrollbar
 )
 #...
end
```

The `slot` keyword in this template is a placeholder for any content that you want to be scrollable in a desktop app.
There really isn't any built-in magic happening here.
The [scrollbar](/api/Hokusai/Blocks/Scrollbar), [clipping region](/api/Hokusai/Blocks/Clipped), and [dynamic sizing](/api/Hokusai/Blocks/Dynamic) are all just plain [Hokusai::Block](/api/Hokusai/Block) which each call different commands.


With `virtual`, `slot`, and the drawing API, you can invent all of your own components.  You don't really need to use the provided blocks if they don't fit your use case.
