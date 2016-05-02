// Copyright 2016 The Shear Authors. All rights reserved.
// Use of this source code is governed by a MIT-style
// license that can be found in the LICENSE file.

import Foundation

public extension Array {
    
    // MARK: - Map, VectorMap
    
    /// Maps a `transform` upon each element of the Array returning an Array of the same shape with the results.
    ///
    /// If transform is a throwing function, we compute the result eagerly.
    public func map<A>(transform: (Element) throws -> A) rethrows -> ComputedArray<A> {
        let baseArray = try self.allElements.map(transform)
        return ComputedArray(DenseArray(shape: self.shape, baseArray: baseArray))
    }
    
    /// Maps a `transform` upon each element of the Array returning an Array of the same shape with the results.
    public func map<A>(transform: (Element) -> A) -> ComputedArray<A> {
        return ComputedArray(shape: self.shape, linear: { transform(self[linear: $0]) } )
    }
    
    /// Maps a `transform` upon a vector of elements from the Array. Either by rows (that is, row vectors of the column-seperated elements) or vectors of first-deminsion-seperated elements.
    ///
    /// If transform is a throwing function, we compute the result eagerly.
    public func vectorMap<A>(byRows rowVector: Bool = true, transform: ([Element]) throws -> [A]) rethrows -> ComputedArray<A> {
        let slice = rowVector ? sequenceFirst : sequenceLast
        if let first = slice.first where first.isScalar { // Slice is a [ArraySlice<Element>], we need to know if its constituent Arrays are themselves scalar.
            return try transform(slice.map { $0.scalar! }).ravel()
        }
        
        let partialResults = try slice.map { try $0.vectorMap(byRows: rowVector, transform: transform) }
        return ComputedArray(rowVector ? DenseArray(collection: partialResults) : DenseArray(collectionOnLastAxis: partialResults))
    }
    
    /// Maps a `transform` upon a vector of elements from the Array. Either by rows (that is, row vectors of the column-seperated elements) or vectors of first-deminsion-seperated elements.
    public func vectorMap<A>(byRows rowVector: Bool = true, transform: ([Element]) -> [A]) -> ComputedArray<A> {
        let enclosed = enclose(rowVector ? [rank-1] : [0]).map { transform([Element]($0.allElements)).ravel() }
        return rowVector ? enclosed.disclose() : enclosed.discloseFirst()
    }
    
    // MARK: - Reduce, Scan
    
    /// Applies the `combine` upon the last axis of the Array; returning an Array with the last element of `self`'s shape dropped.
    public func reduce<A>(initial: A, combine: ((A, Element)-> A)) -> ComputedArray<A> {
        return vectorMap(byRows: true, transform: {[$0.reduce(initial, combine: combine)]})
    }
    
    /// Applies the `combine` upon the last axis of the Array; returning an Array with the last element of `self`'s shape dropped.
    public func reduce(combine: (Element, Element) -> Element) -> ComputedArray<Element> {
        return vectorMap(byRows: true, transform: {[$0.reduce(combine)]})
    }
    
    /// Applies the `combine` upon the last axis of the Array, returning the partial results of it's appplication.
    public func scan<A>(initial: A, combine: (A, Element) -> A) -> ComputedArray<A> {
        return vectorMap(byRows: true, transform: {$0.scan(initial, combine: combine)})
    }
    
    /// Applies the `combine` upon the last axis of the Array, returning the partial results of it's appplication.
    public func scan(combine: (Element, Element) -> Element) -> ComputedArray<Element> {
        return vectorMap(byRows: true, transform: {$0.scan(combine)})
    }
    
    /// Applies the `combine` upon the first axis of the Array; returning an Array with the first element of `self`'s shape dropped.
    public func reduceFirst<A>(initial: A, combine: ((A, Element)-> A)) -> ComputedArray<A> {
        return vectorMap(byRows: false, transform: {[$0.reduce(initial, combine: combine)]})
    }
    
    /// Applies the `combine` upon the first axis of the Array; returning an Array with the first element of `self`'s shape dropped.
    public func reduceFirst(combine: (Element, Element) -> Element) -> ComputedArray<Element> {
        return vectorMap(byRows: false, transform: {[$0.reduce(combine)]})
    }
    
    /// Applies the `combine` upon the first axis of the Array, returning the partial results of it's appplication.
    public func scanFirst<A>(initial: A, combine: (A, Element) -> A) -> ComputedArray<A> {
        return vectorMap(byRows: false, transform: {$0.scan(initial, combine: combine)})
    }
    
    /// Applies the `combine` upon the first axis of the Array, returning the partial results of it's appplication.
    public func scanFirst(combine: (Element, Element) -> Element) -> ComputedArray<Element> {
        return vectorMap(byRows: false, transform: {$0.scan(combine)})
    }

    
}