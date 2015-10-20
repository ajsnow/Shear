//
//  Products.swift
//  Shear
//
//  Created by Andrew Snow on 7/12/15.
//  Copyright © 2015 Andrew Snow. All rights reserved.
//

import Foundation
import Accelerate

// MARK: - Declared Operators

//infix operator * {} /// Element-wise Product Operator
infix operator ⊗ {} /// Tensor (Outer) Product Operator
infix operator × {} /// Cross Product Operator
infix operator ∙ {} /// Dot (Inner) Product Operator

// MARK: - Real Functions

private func elementwiseArrayProduct<A: Array, B: Array where A.Element == B.Element, A.Element: NumericType>
    (left: A, _ right: B) -> DenseArray<A.Element> {
        precondition(left.shape == right.shape, "Arrays must have same shape to be elementwise multiplied")
        
        return DenseArray(shape: left.shape, baseArray: zip(left.allElements, right.allElements).map(*))
}

private func elementwiseScalarProduct<A: Array, Scalar: NumericType where A.Element == Scalar>
    (a: A, scalar: Scalar) -> DenseArray<A.Element> {
        // No preconditions.
        
        let multiplyScalar = { $0 * scalar}
        return DenseArray(shape: a.shape, baseArray: a.allElements.map(multiplyScalar))
}

private func outerProduct<A: Array, B: Array where A.Element == B.Element, A.Element: NumericType>
    (left: A, _ right: B) -> DenseArray<A.Element> {
        // No preconditions.
        
        return outer(left, right, product: *)
}

private func innerProduct<A: Array, B: Array where A.Element == B.Element, A.Element: NumericType>
    (left: A, _ right: B) -> DenseArray<A.Element> {
        // Preconditions are checked by inner.
        
        return inner(left, right, product: *, sum: +)
}

// MARK: - Operators

public func *<A: Array, B: Array where A.Element == B.Element, A.Element: NumericType>
    (left: A, right: B) -> DenseArray<A.Element> {
        return elementwiseArrayProduct(left, right)
}

public func *<A: Array, B: NumericType where A.Element == B>
    (left: A, right: B) -> DenseArray<A.Element> {
        return elementwiseScalarProduct(left, scalar: right)
}

public func *<A: Array, B: NumericType where A.Element == B>
    (left: B, right: A) -> DenseArray<A.Element> {
        return elementwiseScalarProduct(right, scalar: left)
}

public func ⊗<A: Array, B: Array where A.Element == B.Element, A.Element: NumericType>
    (left: A, right: B) -> DenseArray<A.Element> {
        return outerProduct(left, right)
}

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

public func ∙<A: Array, B: Array where A.Element == B.Element, A.Element: NumericType>
    (left: A, right: B) -> DenseArray<A.Element> {
        return innerProduct(left, right)
}
