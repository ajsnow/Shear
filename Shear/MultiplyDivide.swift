// Copyright 2016 The Shear Authors. All rights reserved.
// Use of this source code is governed by a MIT-style
// license that can be found in the LICENSE file.

import Foundation
import Accelerate

// MARK: - Operator Declarations

//infix operator * {} /// Element-wise Product Operator, already declared ;)
infix operator ⊗ {} /// Tensor / Outer Product Operator
infix operator × {} /// Cross Product Operator
infix operator ∙ {} /// Matrix / Dot / Inner Product Operator

// MARK: - Operator Implementations

/// Element-wise Multiplication
public func *<A: TensorProtocol, B: TensorProtocol where A.Element == B.Element, A.Element: NumericType>
    (left: A, right: B) -> Tensor<A.Element> {
        return zip(left, right).map(*)
}

/// Scalar Multiplication
public func *<A: TensorProtocol, X: NumericType where A.Element == X>
    (left: A, right: X) -> Tensor<A.Element> {
        return left.map { $0 * right }
}

/// Left-Scalar Multiplication
public func *<A: TensorProtocol, X: NumericType where A.Element == X>
    (left: X, right: A) -> Tensor<A.Element> {
        return right.map { left * $0 }
}

/// Tensor / Outer Product
public func ⊗<A: TensorProtocol, B: TensorProtocol where A.Element == B.Element, A.Element: NumericType>
    (left: A, right: B) -> Tensor<A.Element> {
        return outer(left, right, product: *)
}

// As far as I can tell, no one actually uses a generalized cross product
// (i.e. N vectors of N+1 length in N+1 space) for anything, so we just
// support the 3-space case.
/// Cross Product
public func ×<A: TensorProtocol, B: TensorProtocol where A.Element == B.Element, A.Element: NumericType>
    (left: A, right: B) -> Tensor<A.Element> {
        precondition(left.shape == right.shape && left.shape == [3], "Shear only supports 3-space cross products. If you actually want this, we'll happily accept a PR for a generalized algo.")
        
        let ax = left[linear: 0],
            ay = left[linear: 1],
            az = left[linear: 2]
        let bx = right[linear: 0],
            by = right[linear: 1],
            bz = right[linear: 2]
        let cx = ay*bz - by*az, // Xcode 7.1 has a hard time with parsing these as an Array literal.
            cy = az*bx - bz*ax,
            cz = ax*by - bx*ay
        return Tensor(shape: [3], values: [cx, cy, cz])
}

/// Matrix / Dot / Inner Product
public func ∙<A: TensorProtocol, B: TensorProtocol where A.Element == B.Element, A.Element: NumericType>
    (left: A, right: B) -> Tensor<A.Element> {
        return inner(left, right, product: *, sum: +)
}

/// Element-wise Division
public func /<A: TensorProtocol, B: TensorProtocol where A.Element == B.Element, A.Element: NumericType>
    (left: A, right: B) -> Tensor<A.Element> {
        return zip(left, right).map(/)
}

/// Scalar Division
public func /<A: TensorProtocol, X: NumericType where A.Element == X>
    (left: A, right: X) -> Tensor<A.Element> {
        return left.map { $0 / right }
}

/// Left-Scalar Division
public func /<A: TensorProtocol, X: NumericType where A.Element == X>
    (left: X, right: A) -> Tensor<A.Element> {
        return right.map { left / $0 }
}
