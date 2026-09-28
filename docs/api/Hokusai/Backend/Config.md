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


## #voice=(value) <Badge type="info" text="public" />

<p>Accessor to toggle voice / speech control</p>
<p>        When on can use voice control.</p>

#### Arguments

*  _value_ - true to use voice


## #speech=(value) <Badge type="info" text="public" />

<p>Accessor to set speech TTS output</p>
        When on, can use [Hokusai.speak](/api/Hokusai.html#speak)

#### Arguments

*  _value_ - true to use speech output


## #voice_model_path=(value) <Badge type="info" text="public" />

<p>Accessor to set the model path for the embedded whisper.cpp library</p>
<p>        (Note: Can download with `hokusai-pocket voice-assets`)</p>

#### Arguments

*  _value_ - path to model (String)


## #voice_accessibility=(value) <Badge type="info" text="public" />

<p>Accessor to toggle accessibility controls</p>

#### Arguments

*  _value_ - true to use voice accessibility


## #voice_accessibility_hot_key=(value) <Badge type="info" text="public" />

<p>Accessor to set the hot key which enables voice control</p>

#### Arguments

*  _value_ - One of the following symbols :apostrophe | :comma | :minus | :period | :slash | :zero | :one | :two | :three | :four | :five | :six | :seven | :eight | :nine | :semicolon | :equal | :a | :b | :c | :d | :e | :f |  :g | :h | :i | :j | :k | :l | :m | :n | :o | :p | :q | :r | :s | :t | :u | :v | :w |  :x | :y | :z | :left_bracket | :backslash | :right_bracket | :grave |  :space | :escape | :enter | :tab | :backspace | :insert | :delete | :right | :left |  :down | :up | :page_up | :page_down | :home | :end | :caps_lock | :scroll_lock |  :num_lock | :print_screen | :pause | :f1 | :f2 | :f3 | :f4 | :f5 | :f6 | :f7 | :f8 | :f9 |  :f10 | :f11 | :f12 | :left_shift | :left_control | :left_alt | :left_super | :right_shift |  :right_control | :right_alt | :right_super | :kb_menu | :kp_0 | :kp_1 | :kp_2 | :kp_3 | :kp_4 |  :kp_5 | :kp_6 | :kp_7 | :kp_8 | :kp_9 | :kp_decimal | :kp_divide | :kp_multiply | :kp_subtract |  :kp_add | :kp_enter | :kp_equal | :back | :menu | :volume_up | :volume_down


## #voice_accessibility_hot_key_type=(value) <Badge type="info" text="public" />

<p>Accessor to set accessibility hot key type (default: toggle)</p>
<p>        Note: Only :toggle is currently supported.</p>

#### Arguments

*  _value_ - one of the following symbols :toggle | :hold


## #voice_accessibility_hot_key_modifiers=(value) <Badge type="info" text="public" />

<p>Accessor to set any hot key modifiers. (Not implemented)</p>

#### Arguments

*  _value_ - an array containing one or more of the following values (:control, :shift, :super, :alt)


## #accessibility(&block) <Badge type="info" text="public" />

<p>Shortcut method for configuring accessibility options.</p>
<p>        Automatically sets voice and audio to `true`</p>

#### Arguments

*  _block_ - a callback to set the following props [:model_path, :hot_key, :hot_key_type, :hot_key_modifiers]

### Examples

```ruby
Hokusai::Backend.run(App) do |config|
  config.accessibility do |aconig|
    aconfig.model_path = "assets/models/ggml-tiny.bin"
    aconfig.hot_key = :space
  end
end
```


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


