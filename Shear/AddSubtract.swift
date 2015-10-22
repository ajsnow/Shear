//
//  AddSubtract.swift
//  Shear
//
//  Created by Andrew Snow on 7/12/15.
//  Copyright © 2015 Andrew Snow. All rights reserved.
//

import Foundation

/// Element-wise Addition
public func +<A: Array, B: Array where A.Element == B.Element, A.Element: NumericType>
    (left: A, right: B) -> DenseArray<A.Element> {
        return map(left, right, transform: +)
}

/// X Addition
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
        return map(left, right, transform: -)
}

/// X Substraction
public func -<A: Array, X: NumericType where A.Element == X>
    (left: A, right: X) -> DenseArray<A.Element> {
        return left.map { $0 - right }
}

/// Left-scalar Subtraction
public func -<A: Array, X: NumericType where A.Element == X>
    (left: X, right: A) -> DenseArray<A.Element> {
        return right.map { left - $0 }
}