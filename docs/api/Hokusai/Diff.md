---
layout: doc
---
# class Diff <Badge type="warning" text="internal" />
A Differ for comparing one set of values to another
When #patch is called, will yield various patches to
true up the old values with the new values.
see: [MovePatch](/api/Hokusai/MovePatch), [InsertPatch](/api/Hokusai/InsertPatch), [UpdatePatch](/api/Hokusai/UpdatePatch), and [DeletePatch](/api/Hokusai/DeletePatch)

## #initialize(before, after) <Badge type="warning" text="internal" />

<p>constructor</p>

#### Arguments

*  _before_ - array of before values
*  _after_ - array of after values


## #patch <Badge type="warning" text="internal" />

<p>yields a sequence of patches to make </p>
<p>          before the same as after</p>

### Returns

Returns nothing


