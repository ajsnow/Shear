// Copyright 2016 The Shear Authors. All rights reserved.
// Use of this source code is governed by a MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// Element-wise Addition
public func +<A: TensorProtocol, B: TensorProtocol where A.Element == B.Element, A.Element: NumericType>
    (left: A, right: B) -> Tensor<A.Element> {
        return zip(left, right).map(+)
}

/// Scalar Addition
public func +<A: TensorProtocol, X: NumericType where A.Element == X>
    (left: A, right: X) -> Tensor<A.Element> {
        return left.map { $0 + right }
}

/// Left-scalar Addition
public func +<A: TensorProtocol, X: NumericType where A.Element == X>
    (left: X, right: A) -> Tensor<A.Element> {
        return right.map { left + $0 }
}

/// Element-wise Subtraction
public func -<A: TensorProtocol, B: TensorProtocol where A.Element == B.Element, A.Element: NumericType>
    (left: A, right: B) -> Tensor<A.Element> {
        return zip(left, right).map(-)
}

/// Scalar Substraction
public func -<A: TensorProtocol, X: NumericType where A.Element == X>
    (left: A, right: X) -> Tensor<A.Element> {
        return left.map { $0 - right }
}

/// Left-scalar Subtraction
public func -<A: TensorProtocol, X: NumericType where A.Element == X>
    (left: X, right: A) -> Tensor<A.Element> {
        return right.map { left - $0 }
}