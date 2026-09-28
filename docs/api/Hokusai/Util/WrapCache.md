---
layout: doc
---
# class WrapCache <Badge type="info" text="public" />
A cache that stores the results of WrapStream.
Utiltiy methods are provided to quickly fetch a subset of tokens
Based on a given window's coordinates (canvas)

## #<<(token) <Badge type="info" text="public" />

<p>Adds a token</p>

#### Arguments

*  _token_ - Hokusai::Util::Wrapped

### Returns

Returns nothing


## #selected_area_for_tokens(target_tokens, selector, &block) <Badge type="info" text="public" />

<p>Populate the selection positions from geometry and yield selection areas</p>

#### Arguments

*  _target_tokens_ - an Array(Hokusai::Util::Wrapped)
*  _selector_ - a Hokusai::Util::Selection
*  _block_ - a callback which takes a param of Hokusai::Rect

### Returns

Returns nothing


## #tokens_for(canvas) <Badge type="info" text="public" />

<p>Get cached tokens for a given Hokusai::Canvas</p>

#### Arguments

*  _canvas_ - a Hokusai::Canvas

### Returns

Return Array(Hokusai::Util::Wrapped)


