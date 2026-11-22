---
layout: doc
---
# class ResponseBody <Badge type="info" text="public" />
Represents a response body from an HTTP Request.
Each request writes to a tmpfile asynchronously, 
the body retains an handle to this io.

## #on_read(chunk_size, &block) <Badge type="info" text="public" />

<p>Reads a buffered stream of (chunk_size) into (block)</p>

#### Arguments

*  _chunk_size_ - bytes to read from the response io at a time
*  _block_ - a callback called with the buffer until the io is read


## #json <Badge type="info" text="public" />

<p>Get this response body parsed as json</p>


## #all <Badge type="info" text="public" />

<p>Get this response body as a string</p>


