// Copyright 2016 The Shear Authors. All rights reserved.
// Use of this source code is governed by a MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// Element-wise Addition
public func +<A: TensorProtocol, B: TensorProtocol>
    (left: A, right: B) -> Tensor<A.Element> where A.Element == B.Element, A.Element: NumericType {
        return zip(left, right).map(+)
}

/// Scalar Addition
public func +<A: TensorProtocol, X: NumericType>
    (left: A, right: X) -> Tensor<A.Element> where A.Element == X {
        return left.map { $0 + right }
}

/// Left-scalar Addition
public func +<A: TensorProtocol, X: NumericType>
    (left: X, right: A) -> Tensor<A.Element> where A.Element == X {
        return right.map { left + $0 }
}

/// Element-wise Subtraction
public func -<A: TensorProtocol, B: TensorProtocol>
    (left: A, right: B) -> Tensor<A.Element> where A.Element == B.Element, A.Element: NumericType {
        return zip(left, right).map(-)
}

/// Scalar Substraction
public func -<A: TensorProtocol, X: NumericType>
    (left: A, right: X) -> Tensor<A.Element> where A.Element == X {
        return left.map { $0 - right }
}

/// Left-scalar Subtraction
public func -<A: TensorProtocol, X: NumericType>
    (left: X, right: A) -> Tensor<A.Element> where A.Element == X {
        return right.map { left - $0 }
}
