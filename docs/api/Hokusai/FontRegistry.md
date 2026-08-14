---
layout: doc
---
# class FontRegistry <Badge type="info" text="public" />
A global registry for storing Hokusai::Backend::Font

## #register(name, font) <Badge type="info" text="public" />

<p>Registers a font</p>

#### Arguments

*  _name_ - font name
*  _font_ - a Hokusai::Backend::Font


## #active_font_name <Badge type="info" text="public" />

<p>Returns the active font's name</p>

### Returns

Returns String


## #activate(name) <Badge type="info" text="public" />

<p>Activates a font by name</p>

#### Arguments

*  _name_ - the font name


## #get(name) <Badge type="info" text="public" />

<p>Fetches a font</p>

#### Arguments

*  _name_ - the name of the registered font

### Returns

Returns Hokusai::Backend::Font or nil


## #active <Badge type="info" text="public" />

<p>Fetches the active font</p>

### Returns

Returns a Hokusai::Backend::Font or nil


