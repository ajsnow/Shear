// Copyright 2016 The Shear Authors. All rights reserved.
// Use of this source code is governed by a MIT-style
// license that can be found in the LICENSE file.

import Foundation

public extension TensorProtocol {
    
    // MARK: - Map, VectorMap
    
    /// Maps a `transform` upon each element of the TensorProtocol returning an TensorProtocol of the same shape with the results.
    ///
    /// If transform is a throwing function, we compute the result eagerly.
    public func map<A>(transform: (Element) throws -> A) rethrows -> Tensor<A> {
        let buffer = try self.allElements.map(transform)
        return Tensor(shape: shape, values: buffer)
    }
    
    /// Maps a `transform` upon each element of the TensorProtocol returning an TensorProtocol of the same shape with the results.
    public func map<A>(transform: (Element) -> A) -> Tensor<A> {
        return Tensor(shape: self.shape, linear: { transform(self[linear: $0]) } )
    }
    
    /// Maps a `transform` upon a vector of elements from the TensorProtocol. Either by rows (that is, row vectors of the column-seperated elements) or vectors of first-deminsion-seperated elements.
    ///
    /// If transform is a throwing function, we compute the result eagerly-ish.
    public func vectorMap<A>(byRows rowVector: Bool = true, transform: ([Element]) throws -> [A]) rethrows -> Tensor<A> {
        let slice = rowVector ? sequenceFirst : sequenceLast
        if let first = slice.first where first.isScalar { // Slice is a [TensorSlice<Element>], we need to know if its constituent Tensors are themselves scalar.
            return try transform(slice.map { $0.scalar! }).ravel()
        }
        
        let partialResults = try slice.map { try $0.vectorMap(byRows: rowVector, transform: transform) }.ravel()
        return rowVector ? partialResults.disclose() : partialResults.discloseFirst()
    }
    
    /// Maps a `transform` upon a vector of elements from the TensorProtocol. Either by rows (that is, row vectors of the column-seperated elements) or vectors of first-deminsion-seperated elements.
    public func vectorMap<A>(byRows rowVector: Bool = true, transform: ([Element]) -> [A]) -> Tensor<A> {
        let enclosed = enclose(rowVector ? [rank-1] : [0]).map { transform([Element]($0.allElements)).ravel() }
        return rowVector ? enclosed.disclose() : enclosed.discloseFirst()
    }
    
    // MARK: - Reduce, Scan
    
    /// Applies the `combine` upon the last axis of the TensorProtocol; returning an TensorProtocol with the last element of `self`'s shape dropped.
    public func reduce<A>(initial: A, combine: ((A, Element)-> A)) -> Tensor<A> {
        return vectorMap(byRows: true, transform: {[$0.reduce(initial, combine: combine)]})
    }
    
    /// Applies the `combine` upon the last axis of the TensorProtocol; returning an TensorProtocol with the last element of `self`'s shape dropped.
    public func reduce(combine: (Element, Element) -> Element) -> Tensor<Element> {
        return vectorMap(byRows: true, transform: {[$0.reduce(combine)]})
    }
    
    /// Applies the `combine` upon the last axis of the TensorProtocol, returning the partial results of it's appplication.
    public func scan<A>(initial: A, combine: (A, Element) -> A) -> Tensor<A> {
        return vectorMap(byRows: true, transform: {$0.scan(initial, combine: combine)})
    }
    
    /// Applies the `combine` upon the last axis of the TensorProtocol, returning the partial results of it's appplication.
    public func scan(combine: (Element, Element) -> Element) -> Tensor<Element> {
        return vectorMap(byRows: true, transform: {$0.scan(combine)})
    }
    
    /// Applies the `combine` upon the first axis of the TensorProtocol; returning an TensorProtocol with the first element of `self`'s shape dropped.
    public func reduceFirst<A>(initial: A, combine: ((A, Element)-> A)) -> Tensor<A> {
        return vectorMap(byRows: false, transform: {[$0.reduce(initial, combine: combine)]})
    }
    
    /// Applies the `combine` upon the first axis of the TensorProtocol; returning an TensorProtocol with the first element of `self`'s shape dropped.
    public func reduceFirst(combine: (Element, Element) -> Element) -> Tensor<Element> {
        return vectorMap(byRows: false, transform: {[$0.reduce(combine)]})
    }
    
    /// Applies the `combine` upon the first axis of the TensorProtocol, returning the partial results of it's appplication.
    public func scanFirst<A>(initial: A, combine: (A, Element) -> A) -> Tensor<A> {
        return vectorMap(byRows: false, transform: {$0.scan(initial, combine: combine)})
    }
    
    /// Applies the `combine` upon the first axis of the TensorProtocol, returning the partial results of it's appplication.
    public func scanFirst(combine: (Element, Element) -> Element) -> Tensor<Element> {
        return vectorMap(byRows: false, transform: {$0.scan(combine)})
    }

    
}