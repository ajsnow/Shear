// Copyright 2016 The Shear Authors. All rights reserved.
// Use of this source code is governed by a MIT-style
// license that can be found in the LICENSE file.

import Foundation

public func ones<Element: NumericType>(shape newShape: [Int]) -> Tensor<Element> {
    return Tensor<Element>(shape: newShape, repeatedValue: 1)
}

public func zeros<Element: NumericType>(shape newShape: [Int]) -> Tensor<Element> {
    return Tensor<Element>(shape: newShape, repeatedValue: 0)
}

public func eye<Element: NumericType>(_ count: Int, rank: Int = 2) -> Tensor<Element> {
    guard rank > 1 else { return ones(shape: [1]) }
    
    let shape = [Int](repeating: count, count: rank)
    return Tensor(shape: shape, cartesian: { $0.allEqual() ? 1 : 0 })
}

public func eye<Element: NumericType>(shape newShape: [Int]) -> Tensor<Element> {
    return Tensor(shape: newShape, cartesian: { $0.allEqual() ? 1 : 0 })
}

public func iota<Element: NumericType>(_ count: Int) -> Tensor<Element> {
    return Tensor(shape: [count], linear: { Element($0) })
}

public func iota(_ count: Int) -> Tensor<Int> {
    return Tensor(shape: [count], linear: { $0 })
}
