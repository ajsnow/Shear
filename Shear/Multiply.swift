//
//  Products.swift
//  Shear
//
//  Created by Andrew Snow on 7/12/15.
//  Copyright © 2015 Andrew Snow. All rights reserved.
//

import Foundation
import Accelerate

// MARK: - Declare operators

infix operator ⊗ {} /// Tensor (Outer) Product Operator
infix operator × {} /// Cross Product Operator
infix operator ∙ {} /// Dot (Inner) Product Operator

// MARK: - Real Functions

private func elementwiseArrayProduct < A: Array, B: Array where A.Element == B.Element, A.Element: NumericType >
    (lhs: A, _ rhs: B) -> DenseArray<A.Element> {
        precondition(lhs.shape == rhs.shape, "Arrays must have same shape to be elementwise added")
        return DenseArray(shape: lhs.shape, baseArray: zip(lhs.allElements, rhs.allElements).map(*))
}

private func elementwiseScalarProduct < A: Array, Scalar: NumericType where A.Element == Scalar >
    (a: A, scalar: Scalar) -> DenseArray<A.Element> {
        let multiplyScalar = { $0 * scalar}
        return DenseArray(shape: a.shape, baseArray: a.allElements.map(multiplyScalar))
}

//private func innerProduct < A: Array, B: Array where A.Element == B.Element, A.Element: NumericType >
//    (lhs: A, _ rhs: B) -> DenseArray<A.Element> {
//        inner(<#T##initial: T##T#>, map: <#T##((T, T)) -> Z#>, lhs: <#T##A#>, rhs: <#T##B#>, reduce: <#T##(T, Z) -> T#>)
//}

private func inner<T, A: SequenceType, B: SequenceType, Z where A.Generator.Element == T, B.Generator.Element == T>
    (initial: T, map: ((T, T)) -> Z, lhs: A, rhs: B, reduce: (T, Z) -> T) -> T {
        return zip(lhs, rhs).map(map).reduce(initial, combine: reduce)
}

private func outer<T, A: SequenceType, B: SequenceType where A.Generator.Element == T, B.Generator.Element == T>
    (map: ((T, T)) -> T, lhs: A, rhs: B) -> [[T]] {
        return lhs.map { a -> [T] in
            rhs.map {
                b -> T in
                map((a, b))
            }
        }
}