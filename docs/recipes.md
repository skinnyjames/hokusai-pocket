# Common Recipes / Idioms

## Setting height on a node programmatically

hokusai-pocket has a single cascading render every tick instead of a compositing process.
In the render, parents nodes are aware of their height/width and use those values to allocate height/width for each of their children.

While this keeps the loop running fast, it can lead to odd outcomes when using blocks that depend on a variable height of children,
such as [Panel](/api/Hokusai/Blocks/Panel) or [Dynamic](/api/Hokusai/Blocks/Dynamic).

In a panel, all child heights but be explicitly known.  
While blocks like `Hokusai::Blocks::Text` automatically set their node height after wrapping, if a text is used as a child of another block, that height will be lost.

Consider the following

```ruby
class Test < Hokusai::Block
  template <<-EOF
  [template]
    panel
      text { :content="first" }
      text { :content="second" }
      vblock { :height="updated_height" }
        text { :content="third" @height_updated="on_height_updated" }
  EOF

  uses(
    panel: Hokusai::Blocks::Panel
    text: Hokusai::Blocks::Text,
    vblock: Hokusai::Blocks::Vblock,
  )

  def first
    "This is a first phrase"
  end

  def second
    "This is a second phrase"
  end

  def third
    "This is a third phrase"
  end

  def on_height_updated(height)
    @third_height = height
  end

  def updated_height
    @third_height || 0.0
  end
end
```

Notice how the third text is wrapped under a Vblock, which does not attempt to read the heights of it's children.

A better way of dealing with dynamic heights is to write a wrapper block.

```ruby
class Wrapper < Hokusai::Block
  template <<-EOF
  [template]
    vblock
      text { :content="content" @height_updated="update_height" }
  EOF

  uses(
    text: Hokusai::Blocks::Text,
    vblock: Hokusai::Blocks::Vblock,
  )

  computed! :content

  def update_height(height)
    # any prop can be set in the block using node.meta
    node.meta.set_prop(:height, height)
  end
end
```

Now our Test block can use the wrapped component.

```ruby
class Test < Hokusai::Block
  template <<-EOF
  [template]
    panel
      text { :content="first" }
      text { :content="second" }
      wrapped { :content="third" }
  EOF

  uses(
    panel: Hokusai::Blocks::Panel
    text: Hokusai::Blocks::Text,
    wrapped: Wrapper,
  )
```

Wrapping components and programatically adjusting height the current best way to handle siblings that have dynamic heights.

## Using the template DSL instead of a template string

hokusai-pocket provides a DSL for composing templates instead of using markup.

The template DSL can inline event handlers and props, and are especially helpful when using loops.

```ruby
class Test < Hokusai::Block
  template do
    child(Hokusai::Blocks::Panel) do
      each_child(Hokusai::Blocks::Text, :list) do |item|
        prop :key do
          item.value
        end
      
        prop :content do
          item.value
        end

        on :click do |event|
          puts "Clicked #{event.pos.x} #{event.pos.y} for #{item.value}"
        end
      end
    end
  end

  def list
   %w[one two buckle my shoe]
  end
end
```

## Making an HTTP request

Let's say you want to populate the ui based on an HTTP request.  We can use [Hokusai::Block#fetch](api/Hokusai/Block.html#fetch-url-opts-path-block)
from any instance method in the block.

For instance, we can put a fetch on mount and populate a list of todos.

```ruby
class Test < Hokusai::Block
  template do
    child(Hokusai::Blocks::Panel) do
      each_child(Hokusai::Blocks::Text, :list) do |item|
        prop :key do
          item.value[:id]
        end
      
        prop :content do
          item.value[:title]
        end

        on :click do |event|
          puts "Clicked #{event.pos.x} #{event.pos.y} for #{item.value.to_s}"
        end
      end
    end
  end

  def list
    @list || []
  end

  def on_mounted
    fetch("https://jsonplaceholder.typicode.com/todos", { method: "GET" }) do |res|
      @list = res.json
    end
  end
end
```

Note: fetch will populate a temporary file with the result, and the callback will have a handle to that file.
After the request is read, Hokusai will attempt to clean up/remove the temporary file.



