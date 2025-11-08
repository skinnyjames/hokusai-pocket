# hokusai pocket

A project for making portable apps and games using [hokusai](https://hokusai.skinnyjames.net)

Work in progress, expect changes.  ideas and contributions are welcome.

# installation

Hokusai pocket uses [barista](https://github.com/skinnyjames/mruby-bin-barista) for bootstrapping itself.

> Note: It is not recommended to build this project with mrbgems.

* `git clone https://github.com/skinnyjames/hokusai-pocket.git && cd hokusai-pocket`
* `barista cli`
  * this command will compile mruby/tree-sitter/raylib and produce a `hokusai-pocket` binary in `bin/`

# usage

To run apps using the binary

* `hokusai-pocket run:target=<somefile.rb>`
  * where `<somefile.rb>` is a hokusai app

To package your app as a binary for the host system from this repo

* `hokusai-pocket build:target=<somefile.rb>`
  * where `<somefile.rb>` is a hokusai app

To cross-compile your app for different platforms (wip, requires docker)

* `hokusai-pocket publish:target=<somefile.rb>`
  * optional arguments include
    * assets_path=[assets folder]
    * platforms=osx (defaults to osx,linux,windows)
    * extras=[folders accessible to the build] (useful for including custom gems)
    * gem_config=[file declaring conf.gems]  (useful for adding gems)

This will create a platforms/[platform]/[target]/[targetfile] for each included platform

# basic example

An example app that can be run with `hokusai-pocket run:target=counter.rb`

```ruby
# counter.rb
class Counter < Hokusai::Block
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

  uses(
    vblock: Hokusai::Blocks::Vblock,
    hblock: Hokusai::Blocks::Hblock,
    label: Hokusai::Blocks::Text,
  )

  attr_accessor :count, :keys, :modal_open

  def count_positive
    count > 0
  end

  def increment(event)
    self.count += 1
  end

  def decrement(event)
    self.count -= 1
  end

  def count_color
    count.negative? ? [244, 0, 0] : [0, 0, 244]
  end

  def initialize(**args)
    @count = 0

    super
  end
end

Hokusai::Backend.run(Counter) do |config|
  config.title = "Counter"     # title
  config.fps = 60              # set frames per second
  config.width = 550
  config.height = 500

  config.after_load do         # register fonts
    Hokusai.fonts.register "default", Hokusai::Backend::Font.default
    Hokusai.fonts.activate "default"
  end
end

```

# development

First, build or obtain a [barista](https://github.com/skinnyjames/mruby-bin-barista) binary

`barista cli` will initially build the following archives in `vendor` in addition to the `hokusai-pocket` binary

    * libtree-sitter.a [task: treesitter]
    * libraylib.a      [task: raylib]
    * libmruby.a       [task: mruby]
    * libhokusai.a     [task: hokusai]

When updating any hokusai code, just run `barista hokusai` to update `libhokusai.a`.

To modify the build process for mruby, raylib, or tree-sitter, adjust the `Brewfile` and rebuild that task.

`barista clean` will remove the `vendor` library.

# testing

More soon.

## dev tour

The project structure is

```
/bin
  hokusai-pocket              (the binary)
/grammar                      (the tree sitter grammar for the templates)
/ruby                         (the hokusai ruby project)
/mrblib                       (the hokusai ruby project as a single file)
/src                          (supporting c files)
Brewfile                      (the build file for the project)
```

# Notes

hokusai pocket supports a basic implementation of `require_relative` in the ruby code. It will perform basic subsitution and generate one large ruby file to be compiled using `mrbc`
