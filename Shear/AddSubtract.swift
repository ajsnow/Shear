//
//  AddSubtract.swift
//  Shear
//
//  Created by Andrew Snow on 7/12/15.
//  Copyright © 2015 Andrew Snow. All rights reserved.
//

import Foundation

// MARK: - Real Functions

private func arraySum<A: Array, B: Array where A.Element == B.Element, A.Element: NumericType>
    (left: A, _ right: B) -> DenseArray<A.Element> {
        precondition(left.shape == right.shape, "Arrays must have same shape to be elementwise added")
        return DenseArray(shape: left.shape, baseArray: zip(left.allElements, right.allElements).map(+))
}

private func scalarSum<A: Array, Scalar: NumericType where A.Element == Scalar>
    (a: A, scalar: Scalar) -> DenseArray<A.Element> {
        let addScalar = { $0 + scalar}
        return DenseArray(shape: a.shape, baseArray: a.allElements.map(addScalar))
}

private func vectorSubtraction<A: Array, B: Array where A.Element == B.Element, A.Element: NumericType>
    (left: A, _ right: B) -> DenseArray<A.Element> {
        precondition(left.shape == right.shape, "Arrays must have same shape to be elementwise subtracted")
        return DenseArray(shape: left.shape, baseArray: zip(left.allElements, right.allElements).map(-))
}

private func scalarSubtraction<A: Array, Scalar: NumericType where A.Element == Scalar>
    (a: A, scalarRight: Scalar) -> DenseArray<A.Element> {
        let subtractScalar = { $0 - scalarRight}
        return DenseArray(shape: a.shape, baseArray: a.allElements.map(subtractScalar))
}

private func scalarSubtraction<A: Array, Scalar: NumericType where A.Element == Scalar>
    (a: A, scalarLeft: Scalar) -> DenseArray<A.Element> {
        let subtractScalar = { scalarLeft - $0 }
        return DenseArray(shape: a.shape, baseArray: a.allElements.map(subtractScalar))
}


// MARK: - Operators

public func +<A: NumericArray, B: NumericArray where A.Element == B.Element, A.Element: NumericType>
    (left: A, right: B) -> DenseArray<A.Element> {
        return arraySum(left, right)
}

public func +<A: Array, Scalar: NumericType where A.Element == Scalar>
    (left: A, right: Scalar) -> DenseArray<A.Element> {
        return scalarSum(left, scalar: right)
}

public func +<A: Array, Scalar: NumericType where A.Element == Scalar>
    (left: Scalar, right: A) -> DenseArray<A.Element> {
        return scalarSum(right, scalar: left)
}

private func -<A: Array, B: Array where A.Element == B.Element, A.Element: NumericType>
    (left: A, right: B) -> DenseArray<A.Element> {
        return vectorSubtraction(left, right)
}

public func -<A: Array, Scalar: NumericType where A.Element == Scalar>
    (left: A, right: Scalar) -> DenseArray<A.Element> {
        return scalarSubtraction(left, scalarRight: right)
}

public func -<A: Array, Scalar: NumericType where A.Element == Scalar>
    (left: Scalar, right: A) -> DenseArray<A.Element> {
        return scalarSubtraction(right, scalarLeft: left)
}