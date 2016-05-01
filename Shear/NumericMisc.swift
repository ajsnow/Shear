// Copyright 2016 The Shear Authors. All rights reserved.
// Use of this source code is governed by a MIT-style
// license that can be found in the LICENSE file.

import Foundation

public func ones<Element: NumericType>(shape newShape: [Int]) -> ComputedArray<Element> {
    return ComputedArray<Element>(shape: newShape, repeatedValue: 1)
}

public func zeros<Element: NumericType>(shape newShape: [Int]) -> ComputedArray<Element> {
    return ComputedArray<Element>(shape: newShape, repeatedValue: 0)
}

public func eye<Element: NumericType>(count: Int, rank: Int = 2) -> ComputedArray<Element> {
    guard rank > 1 else { return ones(shape: [1]) }
    
    let shape = [Int](count: rank, repeatedValue: count)
    return ComputedArray(shape: shape, cartesian: { $0.allEqual() ? 1 : 0 })
}

public func eye<Element: NumericType>(shape newShape: [Int]) -> ComputedArray<Element> {
    return ComputedArray(shape: newShape, cartesian: { $0.allEqual() ? 1 : 0 })
}

public func iota<Element: NumericType>(count: Int) -> ComputedArray<Element> {
    return ComputedArray(shape: [count], linear: { Element($0) })
}

public func iota(count: Int) -> ComputedArray<Int> {
    return ComputedArray(shape: [count], linear: { $0 })
}
