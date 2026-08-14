---
layout: doc
---
# class MusicRegistry <Badge type="info" text="public" />
A global registry for storing Hokusai::Music

## #register(name, music) <Badge type="info" text="public" />

<p>Registers a Hokusai::Music on (name)</p>

#### Arguments

*  _name_ - key to reference this music (String)
*  _music_ - a Hokusai::Music instance


## #get(name) <Badge type="info" text="public" />

<p>fetches a music by name</p>

#### Arguments

*  _name_ - key that references a Hokusai::Music

### Returns

Returns Hokusai::Music


## #delete(name) <Badge type="info" text="public" />

<p>delete a music by name</p>

#### Arguments

*  _name_ - key that references a Hokusai::Music


