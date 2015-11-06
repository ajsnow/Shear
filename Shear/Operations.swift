//
//  Operations.swift
//  Shear
//
//  Created by Andrew Snow on 10/18/15.
//  Copyright © 2015 Andrew Snow. All rights reserved.
//

import Foundation

// MARK: - Sequence the Array into a series of subarrays upon a given dimension
public extension Array {
    
    /// Slices the Array into a sequence of `ArraySlice`s on its nth `deminsion`.
    func sequence(deminsion: Int) -> [ArraySlice<Element>] {
        //        guard !shape.isEmpty else { return [self[ArrayIndex.All]] }
        guard deminsion < rank else { fatalError("An array cannot be sequenced on a deminsion it does not have.") }
        
        let viewIndices = Swift.Array(count: rank, repeatedValue: ArrayIndex.All)
        return (0..<shape[deminsion]).map {
            var nViewIndices = viewIndices
            nViewIndices[deminsion] = .SingleValue($0)
            return self[nViewIndices]
        }
    }
    
    /// Slices the Array on its first dimension.
    /// Since our DenseArray is stored in Row-Major order & the row is the last dimension,
    /// sequencing on the first dimension allows for better memory access patterns than any other sequence.
    var sequenceFirst: [ArraySlice<Element>] {
        return sequence(0)
    }
    
    /// Slices the Array on its last dimension.
    /// Tends to not be cache friendly...
    var sequenceLast: [ArraySlice<Element>] {
        return sequence(rank - 1)
    }
    
}

// MARK: - APL-look-alikes
public extension Array {
    
    /// Returns a new DenseArray with the contents of `self` with `shape`.
    public func reshape(shape: [Int]) -> DenseArray<Element> {
        return DenseArray(shape: shape, baseArray: self)
    }
    
    /// Reshapes a new DenseArray with the contents of `self` as a vector.
    public func ravel() -> DenseArray<Element> {
        return allElements.ravel()
    }
    
    /// Encloses the Array, resulting in a DenseArray whose sole element is Self.
    /// Author's note: I'm not sure this is particularly useful in the context of this library, it's just here to complement the axis version (both of which having been stolen from APL)
    public func enclose() -> DenseArray<Self> {
        return DenseArray(shape: [], baseArray: [self])
    }
    
    /// Encloses the Array upon the `axes` specified, resulting in an Array of Arrays.
    // TODO: Currently only supports a single axis... Add the rest of the function.
    public func enclose(axes: Int...) -> DenseArray<ArraySlice<Element>> {
        // Since this algo is recursive, we only check and operate on the head of the list.
        guard let axis = axes.first else { fatalError("ran out of axes") }
        guard axis < rank else { fatalError("domain") }
        
        let newShape = Swift.Array(shape.enumerate().lazy.filter { $0.index != axis }.map { $0.element })
        
        let internalIndicesList = makeRowMajorIndexGenerator(newShape).map { newIndices -> [ArrayIndex] in
            var internalIndices = newIndices.map { ArrayIndex.SingleValue($0) }
            internalIndices.insert(.All, atIndex: axis)
            return internalIndices
        }
        
        let subarrays = internalIndicesList.map { self[$0] }
        
        return DenseArray(shape: newShape, baseArray: subarrays)
    }
    
    /// Reverse the order of Elements along the first axis
    public func flip() -> DenseArray<Element> {
        return DenseArray(collection: sequenceFirst.reverse())
    }
    
    /// Reverse the order of Elements along the last axis (columns)
    public func reverse() -> DenseArray<Element> {
        return DenseArray(collectionOnLastAxis: sequenceLast.reverse()) // Pretty sure one could do this much more efficiently with linear indexing.
    }
    
    /// Returns a DenseArray whose dimensions are reversed.
    public func transpose() -> DenseArray<Element> {
        let indexGenerator = makeColumnMajorIndexGenerator(shape)
        let transposedSeq = AnySequence(anyGenerator { () -> Element? in
            guard let indices = indexGenerator.next() else { return nil }
            return self[indices]
            })
        return transposedSeq.map { $0 } .reshape(shape.reverse())
    }
    
}

// MARK: - Map, VectorMap, Enumerate
public extension Array {
    
    /// Maps a `transform` upon each element of the Array returning an Array of the same shape with the results.
    public func map<A>(transform: (Element) throws -> A) rethrows -> DenseArray<A> {
        let baseArray = try self.allElements.map(transform)
        return DenseArray(shape: self.shape, baseArray: baseArray)
    }
    
    /// Maps a `transform` upon a vector of elements from the Array. Either by rows (that is, row vectors of the column-seperated elements) or vectors of first-deminsion-seperated elements.
    public func vectorMap<A>(byRows rowVector: Bool = true, transform: ([Element]) throws -> [A]) rethrows -> DenseArray<A> {
        if let s = scalar {
            return try transform([s]).ravel()
        }
        
        let slice = rowVector ? sequenceFirst : sequenceLast
        if let first = slice.first where first.isScalar { // Slice is a [ArraySlice<Element>], we need to know if it's constituent Arrays are themselves scalar.
            return try transform(slice.map { $0.scalar! }).ravel()
        }
        
        let partialResults = try slice.map { try $0.vectorMap(byRows: rowVector, transform: transform) }
        return rowVector ? DenseArray(collection: partialResults) : DenseArray(collectionOnLastAxis: partialResults)
    }
    
    /// Returns a sequence containing pairs of indices and `Element`s.
    public func enumerate() -> AnySequence<([Int], Element)> {
        let indexGenerator = makeRowMajorIndexGenerator(shape)
        
        return AnySequence(anyGenerator {
            guard let indices = indexGenerator.next() else { return nil }
            return (indices, self[indices]) // TODO: Linear indexing is cheaper for DenseArrays. Consider specializing.
            })
    }
    
}

// MARK: - Rotate, Reduce, Scan, RotateFirst, ReduceFirst, ScanFirst
public extension Array {
    
    /// Returns a DenseArray whose columns are shifted `count` times.
    public func rotate(count: Int) -> DenseArray<Element> {
        return vectorMap(byRows: true, transform: {$0.rotate(count)})
    }
    
    /// Applies the `combine` upon the last axis of the Array; returning an Array with the last element of `self`'s shape dropped.
    public func reduce<A>(initial: A, combine: ((A, Element)-> A)) -> DenseArray<A> {
        return vectorMap(byRows: true, transform: {[$0.reduce(initial, combine: combine)]})
    }
    
    /// Applies the `combine` upon the last axis of the Array; returning an Array with the last element of `self`'s shape dropped.
    public func reduce(combine: (Element, Element) -> Element) -> DenseArray<Element> {
        return vectorMap(byRows: true, transform: {[$0.reduce(combine)]})
    }
    
    /// Applies the `combine` upon the last axis of the Array, returning the partial results of it's appplication.
    public func scan<A>(initial: A, combine: (A, Element) -> A) -> DenseArray<A> {
        return vectorMap(byRows: true, transform: {$0.scan(initial, combine: combine)})
    }
    
    /// Applies the `combine` upon the last axis of the Array, returning the partial results of it's appplication.
    public func scan(combine: (Element, Element) -> Element) -> DenseArray<Element> {
        return vectorMap(byRows: true, transform: {$0.scan(combine)})
    }
    
    /// Returns a DenseArray whose first dimension's elements are shifted `count` times.
    public func rotateFirst(count: Int) -> DenseArray<Element> {
        return vectorMap(byRows: false, transform: {$0.rotate(count)})
    }
    
    /// Applies the `combine` upon the first axis of the Array; returning an Array with the first element of `self`'s shape dropped.
    public func reduceFirst<A>(initial: A, combine: ((A, Element)-> A)) -> DenseArray<A> {
        return vectorMap(byRows: false, transform: {[$0.reduce(initial, combine: combine)]})
    }
    
    /// Applies the `combine` upon the first axis of the Array; returning an Array with the first element of `self`'s shape dropped.
    public func reduceFirst(combine: (Element, Element) -> Element) -> DenseArray<Element> {
        return vectorMap(byRows: false, transform: {[$0.reduce(combine)]})
    }
    
    /// Applies the `combine` upon the first axis of the Array, returning the partial results of it's appplication.
    public func scanFirst<A>(initial: A, combine: (A, Element) -> A) -> DenseArray<A> {
        return vectorMap(byRows: false, transform: {$0.scan(initial, combine: combine)})
    }
    
    /// Applies the `combine` upon the first axis of the Array, returning the partial results of it's appplication.
    public func scanFirst(combine: (Element, Element) -> Element) -> DenseArray<Element> {
        return vectorMap(byRows: false, transform: {$0.scan(combine)})
    }
    
}

// MARK: - Generalized Inner and Outer Products

/// Returns the outer product `transform` of `left` and `right`.
/// The outer product is the result of  all elements of `left` and `right` being `transform`'d.
public func outer<X, Y, A: Array, B: Array where A.Element == X, B.Element == X>
    (left: A, _ right: B, product: ((X, X) -> Y)) -> DenseArray<Y> {
        var baseArray = Swift.Array<Y>()
        baseArray.reserveCapacity(Int(left.allElements.count * right.allElements.count))
        
        for l in left.allElements {
            for r in right.allElements {
                baseArray.append(product(l, r))
            }
        }
        
        return DenseArray(shape: left.shape + right.shape, baseArray: baseArray)
}

/// Returns the inner product of `left` and `right`, fused with `transform` and reduced by `combine`.
/// For example the dot product of A & B is defined as `inner(A, B, *, +)`.
public func inner<A: Array, B: Array, X, Y where A.Element == X, B.Element == X>
    (left: A, _ right: B, product: (ArraySlice<X>, ArraySlice<X>) -> DenseArray<Y>, sum: (Y, Y) -> Y) -> DenseArray<Y> {
        let enclosedA = left.enclose(left.rank - 1)
        let enclosedB = right.enclose(0)
        
        let outerProduct = outer(enclosedA, enclosedB, product: product)
        let baseArray = outerProduct.allElements.map{ $0.reduce(sum).allElements.map {$0} }.flatMap {$0}
        return DenseArray(shape: outerProduct.shape, baseArray: baseArray)
}

/// Returns the inner product of `left` and `right`, fused with `transform` and reduced by `combine`.
/// For example the dot product of A & B is defined as `inner(A, B, *, 0, +)`.
public func inner<A: Array, B: Array, X, Y, Z where A.Element == X, B.Element == X>
    (left: A, _ right: B, product: (ArraySlice<X>, ArraySlice<X>) -> DenseArray<Y>, sum: (Z, Y) -> Z, initialSum: Z) -> DenseArray<Z> {
        let enclosedA = left.enclose(left.rank - 1)
        let enclosedB = right.enclose(0)
        
        let outerProduct = outer(enclosedA, enclosedB, product: product)
        let baseArray = outerProduct.allElements.map{ $0.reduce(initialSum, combine: sum).allElements.map {$0} }.flatMap {$0}
        return DenseArray(shape: outerProduct.shape, baseArray: baseArray)
}

// MARK: - Multi-Map

/// Returns an Array with the same shape of the inputs, whose elements are the output of the transform applied to pairs of left's & right's elements.
public func map<A: Array, B: Array, X, Y where A.Element == X, B.Element == X>
    (left: A, _ right: B, transform: (X, X) -> Y) -> DenseArray<Y> {
        precondition(left.shape == right.shape, "Arrays must have the same shape to map a function element-wise")
        
        return DenseArray(shape: left.shape, baseArray: zip(left.allElements, right.allElements).map(transform))
}

extension Array {
    
    /// The length of the Array in a particular dimension.
    func size(d: Int) -> Int {
        return d < rank ? shape[d] : 1
    }
    
    /// The length of the Array in several dimensions.
    func size(ds: [Int]) -> [Int] {
        return ds.map(size)
    }
    
}
