# Shear

A multidimensional array library for Swift.

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

(Unfortunately, we cannot currently convert nested array literals into our types directly. Instead we use a reshape function defined on both our arrays and built-in Swift.Arrays to specify the `shape` (the count in each dimension) of arrays.)

Now, of course, any self-respecting n-array lib will have matrix multiplication. What makes Shear a little more interesting is that our matrix multiplication and dot product (and higher order inner products) are defined simply as `inner(a, b, product: *, sum: +)`. `inner()` is a reusable component that can just as easily compute possible paths from an adjacency matrix (`inner(mat, mat, product: &, sum |)`). Likewise, the pieces that make inner() tick—`.enclose()`, `.reduce()` and the outer product—are exposed as reusable components that clients can easily combine into more advanced operations of their own making.

## Current Features

* Arbitrary dimensional dense arrays with copy-on-write semantics

* Very flexible array slicing: slice whole dimensions, single columns, ranges, or arbitrarily reordered lists on a per-dimension basis

* A featureful (totally a word) suite of operations for sequencing, mapping, reducing, scanning, transforming, and combining arrays 

* Basic math operators for numeric arrays

## Not Current Features

* SIMD for said math-y functions

* Non-Dense/non-Slice arrays

* Optimization

* API stability guarantees

* The ability to catch errors

## API Overview

### Basics

An Array is defined by its elements and shape. The shape is an [Int] where each Int is the count in that dimension. The highest dimension is first, the rows are second to last, and the columns are last. (DenseArrays are stored in row-major order.) Elements are accessed via their Cartesian (`a[0, 6, 4]`) or linear (`a[linear: 34]`) indices. Array can also be sliced into ArraySlices (`a[7, 2..>5, [3, 5, 2]]`) which are shallow views into an underlying Array. Like Swift.ArraySlices, any modification of the elements of an ArraySlice are not reflected in the Array they are sliced from (unlike Swift.ArraySlices, the coordinates of an ArraySlice always start from all zero indices).

### For a given array

In addition to subscript indexing, an Array's elements can be accessed via the `.allElements` CollectionType view:

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

Arrays can also be sequenced across a given dimension to operate on each lower dimensional slice in turn. For instance, if you wish to operate on each matrix in a 3-array, one can simply `.sequenceFirst()`: 

```
for matrix in array3.sequenceFirst() {
	for rowVec in matrix.sequenceFirst() {
		for scalar in rowVec.sequenceFirst() {
			// yet more stuff to do
		}
	}
}

```

(If you hate your processor's cache, you can also sequence on the last (or any other) dimension.)

---

Of course, it's also possible to handle these types of operations at a high level of abstraction.

As one might expect, `.map()` maps a transform upon each element of an array and produces an array of the same shape as output. `.reduce()` and `.scan()` reduce and scan the last dimension (the columns) of an array, while `.reduceFirst()` and `.scanFirst()` have similar effects over the first dimension. Finally, `.vectorMap` maps a transform against either each set of either row vectors or highest-order vectors in the array, which is quite useful for implementing other higher-order functions.

One also has the ability to `.flip()` (along the first axis) `.reverse()` (along the last), `.transpose()` and `.enclose()` — which transforms an array of elements into an array of arrays of elements where the specified axes determines the shape of the resulting inner arrays.

### Between arrays

`zipMap()` maps a function that takes a left and right element from two equally shaped arrays and produces a same-shaped array of results.

`outer()` computes the outer product of two arrays for a given transform (which is all combinations of one set of elements with the other).

`inner()` computes the generalized inner product of two arrays (like the dot-product).

In addition, most of the expected math operators are overloaded to provide element-wise or matrix (or vector or generalized-matrix) functions for numeric arrays.

## Contributing

Pull requests welcome.

## Installation

Currently not in CocoaPods, Carthage, or ready for the Swift Package Manager. Given the alpha state, it seems ill-advised to make it easy to integrate into real projects at this time.

## License

Shear is released under the MIT license.