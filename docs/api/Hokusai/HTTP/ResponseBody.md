---
layout: doc
---
# class ResponseBody <Badge type="info" text="public" />
Represents http response

## #on_read(&block) <Badge type="info" text="public" />

<p>buffered read callback to pipe response data</p>

#### Arguments

*  _block_ - the callback

### Returns

Returns nothing


## #write(content) <Badge type="warning" text="internal" />

<p>Writes content to this response's io</p>

#### Arguments

*  _content_ - a string


## #finish <Badge type="warning" text="internal" />

<p>closes the io</p>


## #json <Badge type="info" text="public" />

<p>Get the response body as a ruby object</p>

### Returns

Returns Object


## #all <Badge type="info" text="public" />

<p>Get response body as a String</p>

### Returns

Returns String


