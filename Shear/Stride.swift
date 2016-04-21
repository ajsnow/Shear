// Copyright 2016 The Shear Authors. All rights reserved.
// Use of this source code is governed by a MIT-style
// license that can be found in the LICENSE file.

import Foundation

// Calculate the stride vector for indexing into the base array
let calculateStride = calculateStrideRowMajor

// Stride for column-major ordering (first dimension on n-arrays)
private func calculateStrideColumnMajor(shape: [Int]) -> [Int] {
    var stride = shape.scan(1, combine: *)
    stride.removeLast()
    return stride
}

// Stride for row-major ordering (last dimension on n-arrays)
private func calculateStrideRowMajor(shape: [Int]) -> [Int] {
    var stride: [Int] = shape.reverse().scan(1, combine: *)
    stride.removeLast()
    return stride.reverse()
}

