---
layout: doc
---
# class Config <Badge type="info" text="public" />
Configure the properties of a hokusai pocket app
Set config flags, fps, title, and register assets.
Passed as a callback parameter to [Hokusai::Backend.run](/api/Hokusai/Backend#run)

## #width=(value) <Badge type="info" text="public" />

<p>Set the width of the window on load</p>

#### Arguments

*  _value_ - The window pixel width (Integer)


## #height=(value) <Badge type="info" text="public" />

<p>Set the height of the window on load</p>

#### Arguments

*  _value_ - The window pixel height (Integer)


## #fps=(value) <Badge type="info" text="public" />

<p>Set the desired frame rate (frames per second)</p>

#### Arguments

*  _value_ - The frames per second (Integer)


## #title=(value) <Badge type="info" text="public" />

<p>Set the title of the window</p>

#### Arguments

*  _value_ - The title of the window (String)


## #config_flags=(value) <Badge type="info" text="public" />

<p>Set any config flags for the window</p>

#### Arguments

*  _value_ - A union of HP_FLAG_*

### Examples

```ruby
Hokusai::Backend.run(App) do |config|
  config.config_flags = HP_FLAG_VSYNC_HINT | HP_FLAG_WINDOW_RESIZABLE
end
# configures window to be resizable and sync frame rate with monitor
```


## #event_waiting=(value) <Badge type="info" text="public" />

<p>Set if application should pause rendering until an event comes through</p>

#### Arguments

*  _value_ - a boolean (false to turn off event waiting)


## #draw_fps=(value) <Badge type="info" text="public" />

<p>Set if the application should draw the FPS in the top left corner</p>

#### Arguments

*  _value_ - true to draw FPS


## #log=(value) <Badge type="info" text="public" />

<p>Set if the application should log to stdout</p>
<p>        Note LOG_LEVEL env var can be set to filter logging</p>

#### Arguments

*  _value_ - true to log


## #audio=(value) <Badge type="info" text="public" />

<p>Accessor to toggle audio (default false)</p>

#### Arguments

*  _value_ - true to use audio


## #touch=(value) <Badge type="info" text="public" />

<p>Accessor to toggle touch input handling (default false)</p>

#### Arguments

*  _value_ - true to use touch events


## #start_automation_driver <Badge type="warning" text="internal" />

<p>Not implemented</p>


## #automate <Badge type="warning" text="internal" />

<p>Not implemented</p>


## #after_load(&block) <Badge type="info" text="public" />

<p>Called after the OpenGL context is established.</p>
<p>This is the place to register assets which depend on the GPU</p>

#### Arguments

*  _block_ - a callback to run code after an OpenGL window is established

### Examples

```ruby
Hokusai::Backend.run(App) do |config|
  config.after_load do
    Hokusai.fonts.register "default", Hokusai::Backend::Font.default
  end
end
```

### Returns

Returns nothing.


## #hot_reload=(entrypoint) <Badge type="info" text="public" />

<p>Sets hot reload entypoint (should probably be same as the app entrypoint)</p>
<p>        Note: for best results, also set `event_waiting = false`</p>

#### Arguments

*  _entrypoint_ - the file path to watch

### Returns

Returns nothing.


## #on_reload <Badge type="warning" text="internal" />

<p>Used by hot_reload= to set the reload logic</p>


