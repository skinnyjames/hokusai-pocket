---
layout: doc
---
# class Block <Badge type="info" text="public" />
A reactive UI component.
        Building block of an application. 
        Subclasses can be run with [Hokusai::Backend.run](/api/Hokusai/Backend#run)
        Blocks can be composed into other blocks templates
#### Examples

```ruby
class Counter < Hokusai::Block
  # create styles to use in templates
  style <<~EOF
  [style]
  additionStyles {
    background: rgb(214, 49, 24);
    cursor: "pointer";
  }
  additionLabel {
    size: 40;
    color: rgb(255,255,255);
  }
  subtractStyles {
    background: rgb(0, 85, 170);
    cursor: "pointer";
  }
  subtractLabel {
    size: 40;
    color: rgb(255, 255, 255);
  }
  EOF
  # define a template composed of other Hokusai::Block
  template <<-EOF
  [template]
    hblock { background="255,255,255" }
      label#count {
        :content="count.to_s"
        size="190" 
        :color="count_color"
      }
    hblock
      vblock#add { ...additionStyles @click="increment"}
        label { 
          content="Add"
          ...additionLabel 
        }
      vblock#subtract { ...subtractStyles @click="decrement" }
        label { 
          content="Subtract"
          ...subtractLabel 
        }
  EOF
  # map template names to Hokusai::Block
  uses(
    vblock: Hokusai::Blocks::Vblock,
    hblock: Hokusai::Blocks::Hblock,
    label: Hokusai::Blocks::Text,
  )
  #
  attr_accessor :count
  #
  def count_positive = count > 0
  def increment(event) = self.count += 1
  def decrement(event) = self.count -= 1
  def count_color = count.negative? ? [244, 0, 0] : [0, 0, 244]
  #
  def initialize(**args)
    @count = 0
    #
    super
  end
end
```


## #node <Badge type="info" text="public" />

<p>The node for this block</p>

### Returns

Returns [Hokusai::Node](/api/Hokusai/Node)


## #publisher <Badge type="warning" text="internal" />

<p>The event publisher for this block</p>

### Returns

Returns [Hokusai::Publisher](/api/Hokusai/Publisher)


## #provides <Badge type="warning" text="internal" />

<p>Specified provisions for this block</p>


## .provide(name, value) <Badge type="info" text="public" />

<p>Provide a value to be injected into any of this block's descendants</p>

#### Arguments

*  _name_ - a name that descandants can use to inject this provision (Symbol)
*  _value_ - a name that maps to a method on this block (Symbol)

### Examples

```ruby
provide :value, :method
```

### Returns

Returns nothing


## .provides <Badge type="warning" text="internal" />

<p>Class level provisions</p>


## .injectables <Badge type="warning" text="internal" />

<p>Class level injections</p>


## .template(template, &block) <Badge type="info" text="public" />

<p>Sets the template for this block</p>
<p>        Using a template string or the NodeBuilder DSL</p>

#### Arguments

*  _template_ - String template (optional if block provided)
*  _block_ - DSL callback (optional if template provided)

### Examples

```ruby
template <<-EOF
[template]
  vblock
    text { content="Hello" size="10" }
EOF
```
```ruby
template do
  child(Hokusai::Blocks::Vblock) do
    child(Hokusai::Blocks::Text) do
      prop :content do
        "Hello"
      end
      prop :size do
        10
      end
    end
  end
end
```

### Returns

Returns nothing


## .build_template <Badge type="warning" text="internal" />

<p>a NodeBuilder callback</p>

### Returns

Returns Proc or nil


## .style(template) <Badge type="info" text="public" />

<p>Define a style template for this block.</p>

#### Arguments

*  _template_ - a style template string or Hokusai::Style

### Examples

```ruby
# Styles are named and map to props
# on nodes/blocks
#
# Defined styles can also be written as "evented" for basic events.
style <<-EOF
[style]
  styleName {
    color: rgb(22,22,22);
    some_prop: 10.0;
    content: "Hello World";
    size: 14
    a_boolean: false
  }
  styleName@hover {
    color: rgb(222,22,22);
  }
EOF
```

### Returns

Returns nothing


## .template_from_file(path) <Badge type="danger" text="deprecated" />

<p>Sets the template for this block using a file</p>

#### Arguments

*  _path_ - a file path that contains a template

### Returns

Returns nothing


## .template_get <Badge type="warning" text="internal" />

<p>Fetches the template for this block</p>
<p>@returns the template (Proc or String)</p>


## .uses(kwargs) <Badge type="info" text="public" />

<p>Defines blocks that this block uses in it's template. Must be defined if using a string template.</p>
        Keys (Symbol) map to template node names, values map to a [Hokusai::Block](/api/Hokusai/Block).

#### Arguments

*  _kwargs_ - the key/value kwargs mapping
   * :key - Symbol that maps to node
   * :value - a Hokusai::Block.class

### Examples

```ruby
uses(
  vblock: Hokusai::Blocks::Vblock,
  text: Hokusai::Blocks::Text
)
```

### Returns

Returns nothing


## .computed(name, kwargs) <Badge type="info" text="public" />

<p>Define a optional computed property with a default value</p>

#### Arguments

*  _name_ - the name of the prop (Symbol)
*  _kwargs_ - computed prop options
   * :default - a default value if the prop is not provided (can be nil)
   * :convert - a proc to convert a string to this type, or an object that responds_to #convert. eg [Hokusai::Outline.convert](/api/Hokusai/Outline#convert)


### Examples

```ruby
computed :radius, default: 10.0, convert: proc(&:to_f)
```
```ruby
computed :color, default: [22,22,22], convert: Hokusai::Color
```

### Returns

Returns nothing


## .computed\!(name) <Badge type="info" text="public" />

<p>Computed prop that is mandatory for this component</p>

#### Arguments

*  _name_ - the name of the prop (Symbol)

### Examples

```ruby
computed! :required_prop
```

### Returns

Returns nothing


## .inject(name, aliased) <Badge type="info" text="public" />

<p>Inject a provision defined by an ancestor</p>

#### Arguments

*  _name_ - the name of the provision (Symbol)
*  _aliased_ - an alias/scoped name to use for this block (default name)

### Examples

```ruby
inject :panel_offset
```
```ruby
inject :panel_offset, :local_offset
```

### Returns

Returns nothing


## .inject\! <Badge type="info" text="public" />

<p>Same as .inject but throws error if not provided</p>


## .compile <Badge type="warning" text="internal" />

<p>Compile a string template or NodeBuilder proc</p>

### Returns

Returns [Hokusai::Node](/api/Hokusai/Node)


## .mount(name, parent_node, options) <Badge type="info" text="public" />

<p>Compile the template, register pub/sub and mount this block and it's children</p>

#### Arguments

*  _name_ - a name for the ast node (default "root")
*  _parent_node_ - a parent node that this block belongs to [Hokusai::Node](/api/Hokusai/Node)
*  _options_ - hash of providers for this block (default: {})

### Examples

```ruby
App.mount
# returns #<App>
```

### Returns

Returns Hokusai::Block


## #initialize(args) <Badge type="info" text="public" />

<p>Constructor for Hokusai::Block.  Can be overriden but must call `super`</p>

#### Arguments

*  _args_ - kwargs for the construtor
   * :node - a Hokusai::Node
   * :providers - a hash of providers

### Examples

```ruby
class App < Hokusai::Block
  #....
  def initialize(**args)
    @local_state = "hello"
    super
  end
end
```


## #providers <Badge type="info" text="public" />

<p>a hash of provisions declared by this block</p>


## #children? <Badge type="info" text="public" />

<p>Returns an array of children (Array(Hokusai::Block)) or nil</p>


## #children <Badge type="info" text="public" />

<p>Returns an array of children (Array(Hokusai::Block)) or []</p>


## #update <Badge type="warning" text="internal" />

<p>Updates the block from publisher</p>


## #emit(name, args, kwargs) <Badge type="info" text="public" />

<p>Emits a custom event</p>

#### Arguments

*  _name_ - name of the event (String)
*  _args_ - a variable length splatted array of *args to pass to the subscriber
*  _kwargs_ - any keyword args to pass to the subscriber

### Examples

```ruby
emit("color_picked", Hokusai::Color.new(22,22,22))
```

### Returns

Returns nothing


## #draw(&block) <Badge type="info" text="public" />

<p>Opens the drawing API</p>

#### Arguments

*  _block_ - a callback that is evaluated in the context of this instance

### Examples

```ruby
draw do
  # draw a green square
  rect(0.0, 0.0, 100.0, 100.0) do |command|
    command.color = Hokusai::Color.new(0, 0, 255)
  end
  # draw a circle with default properties
  circle(50.0, 50.0, 20.0) {}
end
```

### Returns

Returns nothing


## #draw_with <Badge type="info" text="public" />

Same as draw but yields a [Hokusai::Commands](/api/Hokusai/Commands) as the callback parameter


## #fetch(url, opts, path:, &block) <Badge type="info" text="public" />

<p>makes an HTTP request on the libuv loop.  </p>
<p>        Note the response will be written to a temporary file</p>

#### Arguments

*  _url_ - the url to request
*  _opts_ - a hash of options
   * :method - the HTTP method (GET, POST, etc)
   * :headers - a hash of HTTP headers (ex: { 'Content-Type' => 'application/json' })
   * :body - an optional body to send (String)
*  _path:_ - a kwarg for the URI path
*  _block_ - a callback that yields an HTTP response

### Examples

```ruby
fetch("https://https://jsonplaceholder.typicode.com/todos/1", { method: "GET" }) do |res|
  # get the response code
  p res.code
  # get a JSON response as a ruby object
  p res.json
  # OR
  # get a response as a raw string
  p res.all
end
```

### Returns

Returns nothing


## #execute_draw <Badge type="warning" text="internal" />

<p>Execute the list of draw commands saved by the drawing API</p>


## #render(canvas) <Badge type="info" text="public" />

<p>Render method.  Can be overriden but must yield the canvas parameter</p>
<p>                        in order to render this blocks template</p>

#### Arguments

*  _canvas_ - a [Hokusai::Canvas](/api/Hokusai/Canvas) with the suggested layout dimensions

### Returns

Returns nothing


## #on_resize(canvas) <Badge type="info" text="public" />

<p>Called when window is resized.  Override to change state in response to window resize</p>

#### Arguments

*  _canvas_ - a [Hokusai::Canvas](/api/Hokusai/Canvas) with the new dimensions

### Returns

Returns nothing


## #dump <Badge type="info" text="public" />

<p>Dumps a String version of this block</p>
<p>show_props: - a kwarg for including props and events in the dump</p>

### Returns

Returns String


