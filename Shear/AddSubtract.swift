//
//  AddSubtract.swift
//  Shear
//
//  Created by Andrew Snow on 7/12/15.
//  Copyright © 2015 Andrew Snow. All rights reserved.
//

import Foundation

// MARK: - Real Functions

private func arraySum < A: Array, B: Array where A.Element == B.Element, A.Element: NumericType >
    (lhs: A, _ rhs: B) -> DenseArray<A.Element> {
        precondition(lhs.shape == rhs.shape, "Arrays must have same shape to be elementwise added")
        return DenseArray(shape: lhs.shape, baseArray: zip(lhs.allElements, rhs.allElements).map(+))
}

private func scalarSum < A: Array, Scalar: NumericType where A.Element == Scalar >
    (a: A, scalar: Scalar) -> DenseArray<A.Element> {
        let addScalar = { $0 + scalar}
        return DenseArray(shape: a.shape, baseArray: a.allElements.map(addScalar))
}

private func vectorSubtraction < A: Array, B: Array where A.Element == B.Element, A.Element: NumericType >
    (lhs: A, _ rhs: B) -> DenseArray<A.Element> {
        precondition(lhs.shape == rhs.shape, "Arrays must have same shape to be elementwise subtracted")
        return DenseArray(shape: lhs.shape, baseArray: zip(lhs.allElements, rhs.allElements).map(-))
}

private func scalarSubtraction < A: Array, Scalar: NumericType where A.Element == Scalar >
    (a: A, scalarRhs: Scalar) -> DenseArray<A.Element> {
        let subtractScalar = { $0 - scalarRhs}
        return DenseArray(shape: a.shape, baseArray: a.allElements.map(subtractScalar))
}

private func scalarSubtraction < A: Array, Scalar: NumericType where A.Element == Scalar >
    (a: A, scalarLhs: Scalar) -> DenseArray<A.Element> {
        let subtractScalar = { scalarLhs - $0 }
        return DenseArray(shape: a.shape, baseArray: a.allElements.map(subtractScalar))
}


// MARK: - Operator Overloads

public func + < A: Array, B: Array where A.Element == B.Element, A.Element: NumericType >
    (lhs: A, rhs: B) -> DenseArray<A.Element> {
        return arraySum(lhs, rhs)
}

public func + < A: Array, Scalar: NumericType where A.Element == Scalar >
    (lhs: A, rhs: Scalar) -> DenseArray<A.Element> {
        return scalarSum(lhs, scalar: rhs)
}

public func + < A: Array, Scalar: NumericType where A.Element == Scalar >
    (lhs: Scalar, rhs: A) -> DenseArray<A.Element> {
        return scalarSum(rhs, scalar: lhs)
}

private func - < A: Array, B: Array where A.Element == B.Element, A.Element: NumericType >
    (lhs: A, rhs: B) -> DenseArray<A.Element> {
        return vectorSubtraction(lhs, rhs)
}


public func - < A: Array, Scalar: NumericType where A.Element == Scalar >
    (lhs: A, rhs: Scalar) -> DenseArray<A.Element> {
        return scalarSubtraction(lhs, scalarRhs: rhs)
}

public func - < A: Array, Scalar: NumericType where A.Element == Scalar >
    (lhs: Scalar, rhs: A) -> DenseArray<A.Element> {
        return scalarSubtraction(rhs, scalarLhs: lhs)
}