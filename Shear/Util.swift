// Copyright 2016 The Shear Authors. All rights reserved.
// Use of this source code is governed by a MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// Calculate the stride vector for indexing into the base array
let calculateStride = calculateStrideRowMajor

/// Stride for column-major ordering (first dimension on n-arrays)
private func calculateStrideColumnMajor(shape: [Int]) -> [Int] {
    var stride = shape.scan(1, combine: *)
    stride.removeLast()
    return stride
}

/// Stride for row-major ordering (last dimension on n-arrays)
private func calculateStrideRowMajor(shape: [Int]) -> [Int] {
    var stride = shape.reverse().scan(1, combine: *)
    stride.removeLast()
    return stride.reverse()
}

/// N.B. Does NOT check resulting indices are in bounds.
func convertIndices(linear index: Int, stride: [Int]) -> [Int] {
    var index = index
    return stride.map { s in
        let i: Int
        (i, index) = (index / s, index % s)
        return i
    }
}

/// N.B. Does NOT check resulting index is in bounds.
func convertIndices(cartesian indices: [Int], stride: [Int]) -> Int {
    return zip(indices, stride).map(*).reduce(0, combine: +)
}

/// Returns true iff the indicies are within bounds of the given shape.
func indicesInBounds(indices: [Int], forShape shape: [Int]) -> Bool {
    return indices.count == shape.count &&
        !zip(indices, shape).contains { index, count in
        index < 0 || index >= count
    }
}

/// Returns true iff the index is within the bounds of a given count.
func indexInBounds(index: Int, forCount count: Int) -> Bool {
    return index >= 0 && index < count
}