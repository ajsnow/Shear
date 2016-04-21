// Copyright 2016 The Shear Authors. All rights reserved.
// Use of this source code is governed by a MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// Element-wise Addition
public func +<A: Array, B: Array where A.Element == B.Element, A.Element: NumericType>
    (left: A, right: B) -> DenseArray<A.Element> {
        return zipMap(left, right, transform: +)
}

/// Right-scalar Addition
public func +<A: Array, X: NumericType where A.Element == X>
    (left: A, right: X) -> DenseArray<A.Element> {
        return left.map { $0 + right }
}

/// Left-scalar Addition
public func +<A: Array, X: NumericType where A.Element == X>
    (left: X, right: A) -> DenseArray<A.Element> {
        return right.map { left + $0 }
}

/// Element-wise Subtraction
private func -<A: Array, B: Array where A.Element == B.Element, A.Element: NumericType>
    (left: A, right: B) -> DenseArray<A.Element> {
        return zipMap(left, right, transform: -)
}

/// Right-scalar Substraction
public func -<A: Array, X: NumericType where A.Element == X>
    (left: A, right: X) -> DenseArray<A.Element> {
        return left.map { $0 - right }
}

/// Left-scalar Subtraction
public func -<A: Array, X: NumericType where A.Element == X>
    (left: X, right: A) -> DenseArray<A.Element> {
        return right.map { left - $0 }
}