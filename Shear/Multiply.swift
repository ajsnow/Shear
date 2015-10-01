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

infix operator ⊗ {} /// Tensor (Outer) Product Operator
infix operator × {} /// Cross Product Operator
infix operator ∙ {} /// Dot (Inner) Product Operator
//infix operator * {} /// Element-wise Product Operator

// MARK: - Real Functions

private func elementwiseArrayProduct<A: Array, B: Array where A.Element == B.Element, A.Element: NumericType>
    (left: A, _ right: B) -> DenseArray<A.Element> {
        precondition(left.shape == right.shape, "Arrays must have same shape to be elementwise added")
        return DenseArray(shape: left.shape, baseArray: zip(left.allElements, right.allElements).map(*))
}

private func elementwiseScalarProduct<A: Array, Scalar: NumericType where A.Element == Scalar>
    (a: A, scalar: Scalar) -> DenseArray<A.Element> {
        let multiplyScalar = { $0 * scalar}
        return DenseArray(shape: a.shape, baseArray: a.allElements.map(multiplyScalar))
}

private func outerProduct<A: Array, B: Array where A.Element == B.Element, A.Element: NumericType>
    (left: A, _ right: B) -> DenseArray<A.Element> {
        return outer(left, right, *)
}

private func innerProduct<A: Array, B: Array where A.Element == B.Element, A.Element: NumericType>
    (left: A, _ right: B) -> DenseArray<A.Element> {
        return inner(left, right: right, transform: *, initial: 0, combine: +)
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

public func ×<A: Array, B: Array where A.Element == B.Element, A.Element: NumericType>
    (left: A, right: B) -> DenseArray<A.Element> {
        // As far as I can tell, no one actually uses a generalized cross product
        // (i.e. N vectors of N+1 length in N+1 space) for anything, so we just
        // support the 3-space case.
        precondition(left.shape == right.shape && left.shape == [3], "Shear only supports 3-space cross products. If you actually want this, we'll happily accept a PR for a generalized algo.")
        
        let ax = left[0], ay = left[1], az = left[2]
        let bx = right[0], by = right[1], bz = right[2]
        
        return DenseArray(shape: [3], baseArray: [ay*bz - by*az, az*bx - bz*ax, ax*by - bx*ay])
}

public func ∙<A: Array, B: Array where A.Element == B.Element, A.Element: NumericType>
    (left: A, right: B) -> DenseArray<A.Element> {
        return innerProduct(left, right)
}
