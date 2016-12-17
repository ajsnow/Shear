// Copyright 2016 The Shear Authors. All rights reserved.
// Use of this source code is governed by a MIT-style
// license that can be found in the LICENSE file.

import Foundation

// MARK: - Zip

/// Returns a Tensor with pairs of left's and right's elements at each index.
public func zip<A: TensorProtocol, B: TensorProtocol>(_ left: A, _ right: B) -> Tensor<(A.Element, B.Element)> {
    precondition(left.shape == right.shape, "Tensors must have the same shape to zip")
    
    return Tensor(shape: left.shape, linear: { (left[linear: $0], right[linear: $0]) })
}

// MARK: - Generalized Inner and Outer Products

/// Returns a tensor of all possible pairings of elements between `left` and `right`.
public func outer<A: TensorProtocol, B: TensorProtocol>(_ left: A, _ right: B) -> Tensor<(A.Element, B.Element)> {
    return Tensor(shape: left.shape + right.shape, cartesian: { indices in
        let l = left[[Int](indices[0..<left.rank])]
        // (left.rank..<indices.count).count == right.rank
        // Otherwise the programmer has given us an invalid index.
        let r = right[[Int](indices[left.rank..<indices.count])]
        return (l, r)
    })
}

/// Returns the inner product of `left` and `right`, fused with `transform` and reduced by `combine`.
/// For example the dot product of A & B is defined as `inner(A, B, *, +)`.
public func inner<A: TensorProtocol, B: TensorProtocol, C>(_ left: A, _ right: B, product: @escaping (Tensor<A.Element>, Tensor<B.Element>) -> Tensor<C>, sum: @escaping (C, C) -> C) -> Tensor<C> {
    return outer(left.enclose(left.rank - 1), right.enclose(0)).map { product($0.0, $0.1).reduce(sum).scalar! }
}

/// Returns the inner product of `left` and `right`, fused with `transform` and reduced by `combine`.
/// For example the dot product of A & B is defined as `inner(A, B, *, 0, +)`.
public func inner<A: TensorProtocol, B: TensorProtocol, C, D>(_ left: A, _ right: B, product: @escaping (Tensor<A.Element>, Tensor<B.Element>) -> Tensor<C>, sum: @escaping (D, C) -> D, initialSum: D) -> Tensor<D> {
    return outer(left.enclose(left.rank - 1), right.enclose(0)).map { product($0.0, $0.1).reduce(initialSum, combine: sum).scalar! }
}

// MARK: - Multi-Map

// Currently not exposed as part of the public API. Not sure it's useful for much else.
// Returns an TensorProtocol with a rank equal to left's and a shape equal to the sums of the shapes (offset by one if byRows = false), whose (row or highest-dimensional) vectors are the output of the transform applied to pairs of left's & right's (row or highest-dimensional) vectors.
//
// Throwing transforms require eagar-ish computation.
func zipVectorMap<A: TensorProtocol, B: TensorProtocol, C>(_ left: A, _ right: B, byRows rowVector: Bool = true, transform: ([A.Element], [B.Element]) throws -> [C]) rethrows -> Tensor<C> {
    if rowVector {
        guard left.rank == right.rank     && left.shape.dropLast().elementsEqual(right.shape.dropLast()) ||
            left.rank == right.rank + 1 && left.shape.dropLast().elementsEqual(right.shape) else {
                fatalError("Shape of the right array must match the left array in all but the last dimension")
        }
    } else {
        guard left.rank == right.rank     && left.shape.dropFirst().elementsEqual(right.shape.dropFirst()) ||
            left.rank == right.rank + 1 && left.shape.dropFirst().elementsEqual(right.shape) else {
                fatalError("Shape of the right array must match the left array in all but the first dimension")
        }
    }
    
    return try internalZipVectorMap(left, right, byRows: rowVector, transform: transform)
}

// In Swift 3.1, recursion inside of nested functions segfaults the compiler.
fileprivate func internalZipVectorMap<A: TensorProtocol, B: TensorProtocol, C>(_ left: A, _ right: B, byRows rowVector: Bool = true, transform: ([A.Element], [B.Element]) throws -> [C]) rethrows -> Tensor<C> {
    
    let slice = rowVector ? left.sequenceFirst : left.sequenceLast
    if let first = slice.first, first.isScalar { // Slice is a [TensorSlice<Element>], we need to know if it's constituent Tensors are themselves scalar.
        if let r = right.scalar {
            return try transform(slice.map { $0.scalar! }, [r]).ravel()
        } else {
            let rslice = rowVector ? right.sequenceFirst : right.sequenceLast
            return try transform(slice.map { $0.scalar! }, rslice.map { $0.scalar! }).ravel()
        }
    }
    
    let rslice = rowVector ? right.sequenceFirst : right.sequenceLast
    let partialResults = try zip(slice, rslice).map { try internalZipVectorMap($0.0, $0.1, byRows: rowVector, transform: transform) }.ravel()
    return rowVector ? partialResults.disclose() : partialResults.discloseFirst()
}

// Currently not exposed as part of the public API. Not sure it's useful for much else.
// Returns an TensorProtocol with a rank equal to left's and a shape equal to the sums of the shapes (offset by one if byRows = false), whose (row or highest-dimensional) vectors are the output of the transform applied to pairs of left's & right's (row or highest-dimensional) vectors.
func zipVectorMap<A: TensorProtocol, B: TensorProtocol, C, AA, BB>(_ left: A, _ right: B, byRows rowVector: Bool = true, transform: @escaping ([AA], [BB]) -> [C]) -> Tensor<C> where A.Element == AA, B.Element == BB {
    if rowVector {
        guard left.rank == right.rank     && left.shape.dropLast().elementsEqual(right.shape.dropLast()) ||
            left.rank == right.rank + 1 && left.shape.dropLast().elementsEqual(right.shape) else {
                fatalError("Shape of the right array must match the left array in all but the last dimension")
        }
    } else {
        guard left.rank == right.rank     && left.shape.dropFirst().elementsEqual(right.shape.dropFirst()) ||
            left.rank == right.rank + 1 && left.shape.dropFirst().elementsEqual(right.shape) else {
                fatalError("Shape of the right array must match the left array in all but the first dimension")
        }
    }
    let sameShape = left.shape == right.shape
    
    let enclosedLeft = left.enclose(rowVector ? [left.rank-1] : [0])
    let enclosedRight = sameShape ?
        right.enclose(rowVector ? [right.rank-1] : [0]) :
        right.map { ([$0] as [B.Element]).ravel() }
    let enclosed = zip(enclosedLeft, enclosedRight).map { (l, r) -> Tensor<C> in
        let ll = [AA](l.allElements)
        let rr = [BB](r.allElements)
        return transform(ll, rr).ravel()
    }
    return rowVector ? enclosed.disclose() : enclosed.discloseFirst()
}
