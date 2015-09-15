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
//infix operator * {} /// Element-wise Product Operator

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

//public func innerProduct <T, A: Array, B: Array where A.Element == T, B.Element == T, T: NumericType >
//    (lhs: A, _ rhs: B) -> T {
//        
//        if lhs.isVector && rhs.isVector {
//            return inner(T(0), map: *, lhs: lhs.allElements, rhs: rhs.allElements, reduce: +)
//        } else {
//            return inner(T(0), map: innerProduct, lhs: lhs.sequenceFirst, rhs: rhs.sequenceLast, reduce: +)
//        }
//}
//
//public func inner<A: Array, B: Array, X, Y, Z where A.Element == X, B.Element == X>
//    (initial: Z, map: ((X, X)) -> Y, lhs: A, rhs: B, reduce: (Z, Y) -> Z) -> Z {
//        return zip(lhs.sequenceLast, rhs.sequenceFirst).map(map).reduce(initial, combine: reduce)
//}



public func outer<T, Z, A: Array, B: Array where A.Element == T, B.Element == T>
    (lhs: A, rhs: B, transform: ((T, T) -> Z)) -> DenseArray<Z> {
        let rawArray = lhs.allElements.map { a -> [Z] in
            rhs.allElements.map {
                b -> Z in
                transform(a, b)
            }
        }.flatMap {$0}
        
        return DenseArray(shape: lhs.shape + rhs.shape, baseArray: rawArray)
}

public func inner<T, Y, Z, A: Array, B: Array where A.Element == T, B.Element == T>
    (A: A, B: B, transform: ((ArraySlice<T>, ArraySlice<T>) -> DenseArray<Y>), initial: Z, combine: ((Z, Y) -> Z)) -> DenseArray<Z> {        
        let sliceA = A.sequenceFirst
        let sliceB = B.sequenceLast

        let aosA = DenseArray(shape: [sliceA.count], baseArray: sliceA)
        let aosB = DenseArray(shape: [sliceB.count], baseArray: sliceB)
        
        let aoaosAB = outer(aosA, rhs: aosB, transform: transform)
        let unshaped = DenseArray(collection: aoaosAB.allElements.map { $0.reduce(initial, combine: combine)})
        return DenseArray(shape: aoaosAB.shape, baseArray: unshaped)
}

//public func inner<T, Y, Z, A: SequenceType, B: SequenceType where A.Generator.Element == T, B.Generator.Element == T>
//    (lhs: A, rhs: B, transform: ((T, T)) -> Y, initial: Z, combine: (Z, Y) -> Z) -> Z {
//        return zip(lhs, rhs).map(transform).reduce(initial, combine: combine)
//}

public extension Array {
    func reduce<Z>(initial: Z, combine: ((Z, Element)-> Z)) -> DenseArray<Z> {
        if let s = scalar {
            return DenseArray(shape: [], baseArray: [combine(initial, s)])
        }
        
        let slice = sequenceFirst
        guard slice.first?.scalar != nil else {
            return DenseArray(collection: slice.map { $0.reduce(initial, combine: combine) })
        }
        
        let result = slice.map { $0.scalar! }.reduce(initial, combine: combine)
        return DenseArray(shape: [], baseArray: [result])
    }
}

//
//public func outer<T, Z, A: SequenceType, B: SequenceType where A.Generator.Element == T, B.Generator.Element == T>
//    (map: ((T, T)) -> Z, lhs: A, rhs: B) -> [[Z]] {
//        return lhs.map { a -> [Z] in
//            rhs.map {
//                b -> Z in
//                map((a, b))
//            }
//        }
//}

// MARK: - Operators

public func * < A: Array, B: Array where A.Element == B.Element, A.Element: NumericType >
    (lhs: A, rhs: B) -> DenseArray<A.Element> {
        return elementwiseArrayProduct(lhs, rhs)
}