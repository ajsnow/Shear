# Shear

A multidimensional array (hereafter: tensor) library for Swift.

## Status

Shear is in *early alpha*. It's API is unstable & implementation is unoptimized. If you want to get in at the ground floor figuring out how to define n-arrays in the swiftest way possible, here's your opportunity. If you want a sturdy foundation to build a product on today, this likely isn't it.

## Example

Matrix multiplication made easy:

```
let a = [
    1, 2, 3,
    4, 5, 6,
].reshape([2, 3])

let b = [
    1, 2,
    3, 4,
    5, 6,
].reshape([3, 2])

let c = a ∙ b
```

(Unfortunately, we cannot currently convert nested array literals into our types directly. Instead we use a reshape function defined on both our tensors and built-in Arrays to specify the `shape` (the count in each dimension) of arrays.)

Now, of course, any self-respecting n-array lib will have matrix multiplication. What makes Shear a little more interesting is that our matrix multiplication and dot product (and higher order inner products) are defined simply as `inner(a, b, product: *, sum: +)`. `inner()` is a reusable component that can just as easily compute possible paths from an adjacency matrix (`inner(mat, mat, product: &, sum: |)`). Likewise, the pieces that make `inner()` tick—`.enclose()`, `.reduce()` and the outer product—are themselves exposed as reusable components that users can easily combine into more advanced operations of their own making.

## Current Features

* Arbitrary dimensional dense tensors

* Arbitrary dimensional computed tensors for lazy evaluation

* Very flexible tensor slicing: slice whole dimensions, single columns, ranges, or arbitrarily reordered lists on a per-dimension basis

* A featureful (totally a word) suite of operations for sequencing, mapping, reducing, scanning, transforming, and combining tensors 

* Basic math operators for numeric tensors

## Not Current Features

* SIMD for said math-y functions

* Optimization

* API stability guarantees

* The ability to catch errors

## API Overview

### Basics

A Tensor is defined by its elements and shape. The shape is an [Int] where each Int is the count in that dimension. The highest dimension is first, the rows are second to last, and the columns are last. (Dense tensors are stored in row-major order.) Elements are accessed via their Cartesian (`a[0, 6, 4]`) or linear (`a[linear: 34]`) indices. Tensors can also be sliced into other tensors (`a[7, 2..>5, [3, 5, 2]]`) which are shallow views into an underlying tensor.

### For a given tensor

In addition to subscript indexing, a tensor's elements can be accessed via the `.allElements` CollectionType view:

```
for (linearIndex, x) in xs.allElements.enumerate() {
	// do stuff
}
```

If you need the Cartesian indices for each element, this is accommodated by `.coordinate()`:

```
for (indices, x) in xs.coordinate() {
	// more stuff
}
```

Tensors can also be sequenced across a given dimension to operate on each lower dimensional slice in turn. For instance, if you wish to operate on each matrix in a 3-array, one can simply `.sequenceFirst()`: 

```
for matrix in threeArray.sequenceFirst() {
	for rowVec in matrix.sequenceFirst() {
		for scalar in rowVec.sequenceFirst() {
			// yet more stuff to do
		}
	}
}

```

(If you hate your processor's cache, you can also sequence on the last (or any other) dimension.)

---

Of course, it's also possible to handle these types of operations at a higher level of abstraction.

As one might expect, `.map()` maps a transform upon each element of a tensor and produces a tensor of the same shape as output. `.reduce()` and `.scan()` reduce and scan the last dimension (the columns) of a tensor, while `.reduceFirst()` and `.scanFirst()` have similar effects over the first dimension. Finally, `.vectorMap` maps a transform against either each set of either row vectors or highest-order vectors in the tensor, which is quite useful for implementing other higher-order functions.

One also has the ability to `.flip()` (along the first axis) `.reverse()` (along the last), `.transpose()` and `.enclose()` — which transforms a tensor of elements into an tensor of tensors of elements where the specified axes determines the shape of the resulting inner tensors.

### Between tensors

`zip` takes two tensors and returns a lazily computed tensor of matched element pairs. (Which you can then `.map()` etc. to your heart's desire.)

`outer()` pairs of each element of one tensor with every element of the other. Producing a tensor whose shape is the concationation of the argument's shapes.

`inner()` computes the generalized inner product of two tensors (like the dot-product).

In addition, most of the expected math operators are overloaded to provide element-wise or matrix (or vector or generalized-matrix) functions for numeric tensors.

Finally, tensors can have additional elements added to on their first and last axes via `.concat()` and `.append()` and can have dimensions added to the front or back of the shape via `.laminate()` and `.interpose()`.

## Contributing

Pull requests welcome.

## Installation

Currently not in CocoaPods, Carthage, or ready for the Swift Package Manager. Given the alpha state, it seems ill-advised to make it easy to integrate into real projects at this time.

## License

Shear is released under the MIT license.