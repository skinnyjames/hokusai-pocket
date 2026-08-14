---
layout: doc
---
# class Backend <Badge type="info" text="public" />
Runs a [Hokusai::Block](/api/Hokusai/Block) as a Game / Application
        Used by the C/MRuby/Raylb backend
#### Examples

```ruby
Hokusai::Backend.run(BonziBuddy) do |config|
  config.title = "BonziBuddy reloaded"
  config.width = 500
  config.height = 500
  #
  # need to set at least one font if using text
  config.after_load do
    Hokusai.fonts.register "default", Hokusai::Backend::Font.default
    Hokusai.fonts.activate "default"
  end
end
```


## .run(klass, &block) <Badge type="info" text="public" />

<p>Run a hokusai-pocket app.  Blocking until app is exited.</p>

#### Arguments

*  _klass_ - a Hokusai::Block.class
*  _block_ - a callback to configure the application


## #initialize(app, config) <Badge type="warning" text="internal" />

<p>constructor for Backend</p>

#### Arguments

*  _app_ - a Hokusai::Block.class
*  _config_ - a Hokusai::Backend::Config


