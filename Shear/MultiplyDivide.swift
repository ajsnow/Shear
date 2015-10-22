//
//  Products.swift
//  Shear
//
//  Created by Andrew Snow on 7/12/15.
//  Copyright © 2015 Andrew Snow. All rights reserved.
//

import Foundation
import Accelerate

// MARK: - Operator Declarations

//infix operator * {} /// Element-wise Product Operator, already declared ;)
infix operator ⊗ {} /// Tensor / Outer Product Operator
infix operator × {} /// Cross Product Operator
infix operator ∙ {} /// Matrix / Dot / Inner Product Operator

// MARK: - Operator Implementations

/// Element-wise Multiplication
public func *<A: Array, B: Array where A.Element == B.Element, A.Element: NumericType>
    (left: A, right: B) -> DenseArray<A.Element> {
        return map(left, right, transform: *)
}

/// Scalar Multiplication
public func *<A: Array, X: NumericType where A.Element == X>
    (left: A, right: X) -> DenseArray<A.Element> {
        return left.map { $0 * right }
}

/// Left-Scalar Multiplication
public func *<A: Array, X: NumericType where A.Element == X>
    (left: X, right: A) -> DenseArray<A.Element> {
        return right.map { left * $0 }
}

/// Tensor / Outer Product
public func ⊗<A: Array, B: Array where A.Element == B.Element, A.Element: NumericType>
    (left: A, right: B) -> DenseArray<A.Element> {
        return outer(left, right, product: *)
}

/// Cross Product
// As far as I can tell, no one actually uses a generalized cross product
// (i.e. N vectors of N+1 length in N+1 space) for anything, so we just
// support the 3-space case.
public func ×<A: Array, B: Array where A.Element == B.Element, A.Element: NumericType>
    (left: A, right: B) -> DenseArray<A.Element> {
        precondition(left.shape == right.shape && left.shape == [3], "Shear only supports 3-space cross products. If you actually want this, we'll happily accept a PR for a generalized algo.")
        
        let ax = left[linear: 0],
            ay = left[linear: 1],
            az = left[linear: 2]
        let bx = right[linear: 0],
            by = right[linear: 1],
            bz = right[linear: 2]
        let cx = ay*bz - by*az, // Xcode 7.1b has a hard time with parsing these as a Swift.Array literal.
            cy = az*bx - bz*ax,
            cz = ax*by - bx*ay
        return DenseArray(shape: [3], baseArray: [cx, cy, cz])
}

/// Matrix / Dot / Inner Product
public func ∙<A: Array, B: Array where A.Element == B.Element, A.Element: NumericType>
    (left: A, right: B) -> DenseArray<A.Element> {
        return inner(left, right, product: *, sum: +)
}

/// Element-wise Division
public func /<A: Array, B: Array where A.Element == B.Element, A.Element: NumericType>
    (left: A, right: B) -> DenseArray<A.Element> {
        return map(left, right, transform: /)
}

/// Scalar Multiplication
public func /<A: Array, X: NumericType where A.Element == X>
    (left: A, right: X) -> DenseArray<A.Element> {
        return left.map { $0 / right }
}

/// Left-Scalar Multiplication
public func /<A: Array, X: NumericType where A.Element == X>
    (left: X, right: A) -> DenseArray<A.Element> {
        return right.map { left / $0 }
}
