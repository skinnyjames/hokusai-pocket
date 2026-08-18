---
layout: doc
---
# class WrapCache <Badge type="info" text="public" />
A cache that stores the results of WrapStream.
Utiltiy methods are provided to quickly fetch a subset of tokens
Based on a given window's coordinates (canvas)

## .diff <Badge type="info" text="public" />

<p>returns range denoting the index of the changed lines</p>
<p>from 2 different strings.</p>


## #<<(token) <Badge type="info" text="public" />

<p>Adds a token</p>

#### Arguments

*  _token_ - Hokusai::Util::Wrapped

### Returns

Returns nothing


## #selected_area_for_tokens(tokens, selector, options) <Badge type="info" text="public" />

<p>Gets the area coordinates for a selection</p>
<p>        to draw a text selection background.</p>

#### Arguments

*  _tokens_ - the result of WrapCache#tokens_for
*  _selector_ - a [Hokusai::Util::Selection](/api/Hokusai/Util/Selection) object
*  _options_ - kwargs options copy - boolean to copy selected tokens padding - a Hokusai::Padding object

### Returns

Returns Hokusai::Util::WrapCachePayload


## #tokens_for(canvas) <Badge type="info" text="public" />

<p>Get cached tokens for a given Hokusai::Canvas</p>

#### Arguments

*  _canvas_ - a Hokusai::Canvas

### Returns

Return Array(Hokusai::Util::Wrapped)


