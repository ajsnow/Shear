//
//  Stride.swift
//  Shear
//
//  Created by Andrew Snow on 10/18/15.
//  Copyright © 2015 Andrew Snow. All rights reserved.
//

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

