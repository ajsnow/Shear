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
        if (isEmpty || isScalar) && deminsion == 0 {
            return [ArraySlice(baseArray: self)]
        }
        guard deminsion < rank else { fatalError("An array cannot be sequenced on a deminsion it does not have") }
        
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
        return sequence(rank != 0 ? rank - 1 : 0)
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
    
    // TODO: Supporting the full APL-style axes enclose requires support for general dimensional reodering.
    /// Encloses the Array upon the `axes` specified, resulting in an Array of Arrays.
    /// If no `axes` are provided, encloses over the whole Array.
    /// Enclose is equivilant to APL's enclose when the axes are in accending order.
    /// i.e.
    ///     A.enclose(2, 0, 5) == ⊂[0 2 5]A
    ///     A.enclose(2, 0, 5) != ⊂[2 0 5]A
    public func enclose(axes: Int...) -> DenseArray<ArraySlice<Element>> {
        guard !axes.isEmpty else { return ([ArraySlice(baseArray: self)] as [ArraySlice<Element>]).ravel() }
        
        let axes = Set(axes).sort() // Filter out any repeated axes.
        guard !axes.contains({ $0 >= rank }) else { fatalError("No axis can be greater or equal to the rank of the array") }
        
        let newShape = [Int](shape.enumerate().lazy.filter { !axes.contains($0.index) }.map { $0.element })
        
        let internalIndicesList = makeRowMajorIndexGenerator(newShape).map { newIndices -> [ArrayIndex] in
            var internalIndices = newIndices.map { ArrayIndex.SingleValue($0) }
            for a in axes {
                internalIndices.insert(.All, atIndex: a) // N.B. This only works when the axes are sorted.
            }
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
    
    /// Returns a DenseArray with the contents of additionalItems appended to the last axis of the Array.
    /// Note: this addes extra length in all but the last dimension, it does not change the shape.
    /// Use DenseArray(collection: [Arrays]) to make a higher order Array.
    public func append<A: Array where A.Element == Element>(additionalItems: A) -> DenseArray<Element> {
        return zipVectorMap(self, additionalItems, byRows: true, transform: {$0 + $1})
    }
    
    /// Returns a DenseArray with the contents of additionalItems concatenated to the first axis of the Array.
    /// Note: this addes extra length in all but the first dimension, it does not change the shape.
    /// Use DenseArray(collection: [Arrays]) to make a higher order Array.
    public func concat<A: Array where A.Element == Element>(additionalItems: A) -> DenseArray<Element> {
        return zipVectorMap(self, additionalItems, byRows: false, transform: {$0 + $1})
    }
    
    /// Returns a DenseArray with the contents of additionalItems appended to the last axis of the Array.
    /// Note: this addes extra length in all but the last dimension, it does not change the shape.
    /// Use DenseArray(collection: [Arrays]) to make a higher order Array.
    public func append(additionalItem: Element) -> DenseArray<Element> {
        return vectorMap(byRows: true, transform: {$0 + [additionalItem]})
    }
    
    /// Returns a DenseArray with the contents of additionalItems concatenated to the first axis of the Array.
    /// Note: this addes extra length in all but the first dimension, it does not change the shape.
    /// Use DenseArray(collection: [Arrays]) to make a higher order Array.
    public func concat(additionalItem: Element) -> DenseArray<Element> {
        return vectorMap(byRows: false, transform: {$0 + [additionalItem]})
        // This could be optimized to the following:
        //     return DenseArray(shape: [shape[0] + 1] + shape.dropFirst(), baseArray: [Element](allElements) + [Element](count: shape.dropFirst().reduce(*), repeatedValue: additionalItem))
        // But given all preformance we're leaving on the table elsewhere, it seems silly to break the nice symmetry for an unimportant function.
        // I've also not benched, so this could turn out to be a pessimization, though that would shock me.
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
    (left: A, _ right: B, transform: (X, X) throws -> Y) rethrows -> DenseArray<Y> {
        precondition(left.shape == right.shape, "Arrays must have the same shape to map a function element-wise")
        
        return try DenseArray(shape: left.shape, baseArray: zip(left.allElements, right.allElements).map(transform))
}

// Currently not exposed as part of the public API. Not sure it's useful for much else.
/// Returns an Array with a rank equal to left's and a shape equal to the sums of the shapes (offset by one if byRows = false), whose (row or highest-dimensional) vectors are the output of the transform applied to pairs of left's & right's (row or highest-dimensional) vectors.
func zipVectorMap<A: Array, B: Array, X, Y where A.Element == X, B.Element == X>(left: A, _ right: B, byRows rowVector: Bool = true, transform: ([X], [X]) throws -> [Y]) rethrows -> DenseArray<Y> {
    if rowVector {
        guard (left.rank == right.rank || left.rank == right.rank + 1) &&
            !zip(left.shape.dropLast(), right.shape).contains(!=) else {
                fatalError("Shape of additionalItems must match the base array in all but the last dimension")
        }
    } else {
        guard (left.rank == right.rank && !zip(left.shape.dropFirst(), right.shape.dropFirst()).contains(!=)) ||
            (left.rank == right.rank + 1 && !zip(left.shape.dropFirst(), right.shape).contains(!=)) else {
                fatalError("Shape of additionalItems must match the base array in all but the first dimension")
        }
    }
    
    func internalZipVectorMap<A: Array, B: Array, X, Y where A.Element == X, B.Element == X>(left: A, _ right: B, byRows rowVector: Bool = true, transform: ([X], [X]) throws -> [Y]) rethrows -> DenseArray<Y> {
        if let s = left.scalar, r = right.scalar {
            return try transform([s], [r]).ravel()
        }
        
        let slice = rowVector ? left.sequenceFirst : left.sequenceLast
        if let first = slice.first where first.isScalar { // Slice is a [ArraySlice<Element>], we need to know if it's constituent Arrays are themselves scalar.
            if let r = right.scalar {
                return try transform(slice.map { $0.scalar! }, [r]).ravel()
            } else {
                let rslice = rowVector ? right.sequenceFirst : right.sequenceLast
                return try transform(slice.map { $0.scalar! }, rslice.map { $0.scalar! }).ravel()
            }
        }
        
        let rslice = rowVector ? right.sequenceFirst : right.sequenceLast
        let partialResults = try zip(slice, rslice).map { try zipVectorMap($0.0, $0.1, byRows: rowVector, transform: transform) }
        return rowVector ? DenseArray(collection: partialResults) : DenseArray(collectionOnLastAxis: partialResults)
    }
    
    return try internalZipVectorMap(left, right, byRows: rowVector, transform: transform)
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
