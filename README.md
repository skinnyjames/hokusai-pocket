# hokusai pocket

A project for making portable apps and games using [hokusai](https://hokusai.skinnyjames.net)

Work in progress, expect changes.  ideas and contributions are welcome.

# installation

## prerequisites

* make and build tools
* a c compiler
* ruby/rake

Running `hokusai-pocket new` will walk you through setting up a project

It will create the following project structure

```
project/
  .pocket (a config file that defines the gems)
  src/
    app.rb (default app entrypoint)
  dist/
    default/ (the app gets compiled here)
    web/
  vendor/ (source code for mruby / raylib / tree-sitter)
    ...
  target/
    default/ (default target is the build host)
      bin/
        mrbc
        mruby
        ...
      include/
        raylib.h
        mruby.h
        hokusai-pocket.h
        ...
      lib/
        libmruby.a
        libtree-sitter.a
        libpocket.a
        ...
    web/ (addtional targets)
    ...
```

* `hokusai-pocket compile -t <target>`

After setup, the `compile` command will recompile the vendor source for different targets. 

* `hokusai-pocket dev -t <target> -a <hokusai app>` 

This command will compile and run `src/app.rb` for `<target>`, omit the target to build for the host system.

# backend

The target hokusai application must end with a `Hokusai::Backend` statement

An example app:

```ruby
class App < Hokusai::Block
  style <<-EOF
  [style]
  style {
    radius: 40.0;
    color: rgb(222, 222, 0);
  }
  EOF
  template <<-EOF
  [template]
    circle { ...style }
  EOF

  uses(circle: Hokusai::Blocks::Circle)
end

# Need to declare `Hokusai::Backend::run`
Hokusai::Backend.run(App) do |config|
  # configure backend
  config.title = "Counter"
  config.fps = 60
  config.width = 700
  config.height = 500
  config.after_load do
    # need to register a font to use text
    Hokusai.fonts.register "default", Hokusai::Backend::Font.default
    Hokusai.fonts.activate "default"

    # or load one from a file
    Hokusai.fonts.register "some-file", Hokusai::Backend::Font.from("some-file.ttf")

    # to load specific codepoints
    codepoints = "abcdefhijklmnop"
    Hokusai.fonts.register "some-file", Hokusai::Backend::Font.from_ext("some-file.ttf", 120, codepoints)
  end
end
```

# development

## prerequisites

* make and build tools
* a c compiler
* ruby/rake
* crystal

1. clone this repository and cd into it.
2. build the `hokusai-pocket` binary `shards build`
3. setup a project with vendor code `./bin/hokusai-pocket new example`
3. run system tests against the installation `./bin/hokusai-pocket system-test example`.

## dev tour

The project structure is

```
/bin
  hokusai-pocket
/builder (a barista project for the hokusai-pocket binary)
/grammar (the tree sitter grammar for the templates)
/ruby (the hokusai ruby project)
/include (supporting headers)
  /ast
  /hp
/src (supporting c files)
  /ast (template code for the tree-sitter ast)
  /hp (glues raylib/mruby/ast code)
/test (c tests using GREATEST.h)
```

`hokusai-pocket system-test <installation>` will compile the project using the setup source from `<installation>`

# Notes

hokusai pocket supports a basic implementation of `require_relative` in the ruby code. It will perform basic subsitution and generate one large ruby file to be compiled using `mrbc`

`shards build` will bake the ruby and c source code into the resulting executable.  Running `hokusai-pocket setup` will write these files back to the file system to be compiled.

The executable is built with a tool called Barista, which runs a dependency graph of tasks concurrently via cli entrpoints.  It has support for platform detection, running arbitrary commands and using templates.

For more information on the barista project, please see: [the repository](https://codeberg.org/skinnyjames/barista)