// Copyright 2016 The Shear Authors. All rights reserved.
// Use of this source code is governed by a MIT-style
// license that can be found in the LICENSE file.

import Foundation

public func ones<Element: NumericType>(shape newShape: [Int]) -> DenseArray<Element> {
    return DenseArray<Element>(shape: newShape, repeatedValue: 1)
}

public func zeros<Element: NumericType>(shape newShape: [Int]) -> DenseArray<Element> {
    return DenseArray<Element>(shape: newShape, repeatedValue: 0)
}

public func eye<Element: NumericType>(count: Int, rank: Int = 2) -> DenseArray<Element> {
    guard rank > 1 else { return DenseArray<Element>(shape: [1], baseArray: [1]) }
    
    let shape = [Int](count: rank, repeatedValue: count)
    var array: DenseArray<Element> = zeros(shape: shape)
    for i in 0..<count {
        let indices = [Int](count: rank, repeatedValue: i)
        array[indices] = 1
    }
    return array
}

public func eye<Element: NumericType>(shape newShape: [Int]) -> DenseArray<Element> {
    var array: DenseArray<Element> = zeros(shape: newShape)
    let count = newShape.minElement()!
    
    for i in 0..<count {
        let indices = [Int](count: newShape.count, repeatedValue: i)
        array[indices] = 1
    }
    
    return array
}

public func iota<Element: NumericType>(count: Int) -> DenseArray<Element> {
    let range = Range(0..<count)
    return DenseArray(shape: [count], baseArray: range.map { $0 as! Element })
}

public func iota(count: Int) -> DenseArray<Int> {
    let range = Range(0..<count)
    return DenseArray(shape: [count], baseArray: range.map { $0 })
}
