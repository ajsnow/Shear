// Copyright 2016 The Shear Authors. All rights reserved.
// Use of this source code is governed by a MIT-style
// license that can be found in the LICENSE file.

import Foundation

// MARK: - Sequence the Array into a series of subarrays upon a given dimension
public extension Array {
    
    /// Slices the Array into a sequence of `ArraySlice`s on its nth `deminsion`.
    func sequence(deminsion: Int) -> [ArraySlice<Element>] {
        if (isEmpty || isScalar) && deminsion == 0 { // TODO: Consider making sequencing scalar or empty arrays an error.
            return [ArraySlice(baseArray: self)]
        }
        guard deminsion < rank else { fatalError("An array cannot be sequenced on a deminsion it does not have") }
        
        let viewIndices = [ArrayIndex](count: rank, repeatedValue: ArrayIndex.All)
        return (0..<shape[deminsion]).map {
            var nViewIndices = viewIndices
            nViewIndices[deminsion] = .SingleValue($0)
            return self[nViewIndices]
        }
    }
    
    /// Slices the Array on its first dimension.
    /// Since our DenseArray is stored in Row-Major order, sequencing on the first
    /// dimension allows for better memory access patterns than any other sequence.
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
    
    /// Returns a new ComputedArray with the contents of `self` with `shape`.
    public func reshape(shape: [Int]) -> ComputedArray<Element> {
        return ComputedArray(shape: shape, baseArray: self)
    }
    
    /// Returns a new ComputedArray with the contents of `self` as a vector.
    public func ravel() -> ComputedArray<Element> {
        return ComputedArray(shape: [Int(allElements.count)], baseArray: self)
    }
    
    // TODO: Supporting the full APL-style axes enclose requires support for general dimensional reodering.
    /// Encloses the Array upon the `axes` specified, resulting in an Array of Arrays.
    /// If no `axes` are provided, encloses over the whole Array.
    /// Enclose is equivilant to APL's enclose when the axes are in accending order.
    /// i.e.
    ///     A.enclose(2, 0, 5) == ⊂[0 2 5]A
    ///     A.enclose(2, 0, 5) != ⊂[2 0 5]A
    public func enclose(axes: Int...) -> ComputedArray<ComputedArray<Element>> {
        return enclose(axes)
    }
    
    // TODO: Supporting the full APL-style axes enclose requires support for general dimensional reodering.
    /// Encloses the Array upon the `axes` specified, resulting in an Array of Arrays.
    /// If no `axes` are provided, encloses over the whole Array.
    /// Enclose is equivilant to APL's enclose when the axes are in accending order.
    /// i.e.
    ///     A.enclose([2, 0, 5]) == ⊂[0 2 5]A
    ///     A.enclose([2, 0, 5]) != ⊂[2 0 5]A
    public func enclose(axes: [Int]) -> ComputedArray<ComputedArray<Element>> {
        guard !axes.isEmpty else { return ([ComputedArray(self)] as [ComputedArray<Element>]).ravel() }
        
        let axes = Set(axes).sort() // Filter out any repeated axes.
        guard !axes.contains({ !checkBounds($0, forCount: rank) }) else { fatalError("All axes must be between 0..<rank") }
        
        let newShape = [Int](shape.enumerate().lazy.filter { !axes.contains($0.index) }.map { $0.element })
        
        let internalIndicesList = makeRowMajorIndexGenerator(newShape).map { newIndices -> [ArrayIndex] in
            var internalIndices = newIndices.map { ArrayIndex.SingleValue($0) }
            for a in axes {
                internalIndices.insert(.All, atIndex: a) // N.B. This only works when the axes are sorted.
            }
            return internalIndices
        }
        
        return ComputedArray(shape: newShape, linear: { ComputedArray(self[internalIndicesList[$0]]) })
    }
    
    /// Reverse the order of Elements along the last axis (columns).
    public func reverse() -> ComputedArray<Element> {
        return self.vectorMap(byRows: true, transform: { $0.reverse() } )
    }
    
    /// Reverse the order of Elements along the first axis.
    public func flip() -> ComputedArray<Element> {
        return self.vectorMap(byRows: false, transform: { $0.reverse() } )
    }
    
    /// Returns a ComputedArray whose dimensions are reversed.
    public func transpose() -> ComputedArray<Element> {
        return ComputedArray(shape: shape.reverse(), cartesian: {indices in
            self[indices.reverse()]
        })
    }
    
    /// Returns a DenseArray with the contents of additionalItems appended to the last axis of the Array.
    ///
    /// e.g.
    ///    1 2 | 5 6 --> 1 2 5 6
    ///    3 4 | 7 8 --> 3 4 7 8
    public func append<A: Array where A.Element == Element>(additionalItems: A) -> ComputedArray<Element> {
        return zipVectorMap(self, additionalItems, byRows: true, transform: { $0 + $1 } )
        //        guard rank == additionalItems.rank && shape.dropLast().elementsEqual(additionalItems.shape.dropLast()) ||
        //            rank == additionalItems.rank + 1 && shape.dropLast().elementsEqual(additionalItems.shape) else {
        //               fatalError("Shape of additionalItems must match the base array in all but the last dimension")
        //        }
        //
        //        var newShape = shape
        //        newShape[newShape.count - 1] += rank == additionalItems.rank ? additionalItems.shape.last! : 1
        //        return ComputedArray(shape: newShape, cartesian: { indices in
        //            if indices.last! < self.shape.last! {
        //                return self[indices]
        //            }
        //            var viewIndices = [Int](indices.dropLast()) + [indices.last! - self.shape.last!] as [Int]
        //            if self.rank != additionalItems.rank {
        //                viewIndices = [Int](viewIndices.dropLast())
        //            }
        //            return additionalItems[viewIndices]
        //        })
    }
    
    /// Returns a DenseArray with the contents of additionalItems concatenated to the first axis of the Array.
    ///
    /// e.g.
    ///    1 2 | 5 6 --> 1 2
    ///    3 4 | 7 8 --> 3 4
    ///                  5 6
    ///                  7 8
    public func concat<A: Array where A.Element == Element>(additionalItems: A) -> ComputedArray<Element> {
        return zipVectorMap(self, additionalItems, byRows: false, transform: {$0 + $1})
    }
    
    /// Returns a DenseArray with a rank - 1 array of additionalitem appended to the last axis of the Array.
    public func append(additionalItem: Element) -> ComputedArray<Element> {
        return vectorMap(byRows: true, transform: {$0 + [additionalItem]})
    }
    
    /// Returns a DenseArray with a rank - 1 array of additionalitem concatenated to the first axis of the Array.
    public func concat(additionalItem: Element) -> ComputedArray<Element> {
        return vectorMap(byRows: false, transform: {$0 + [additionalItem]})
        // This could be optimized to the following:
        //     return DenseArray(shape: [shape[0] + 1] + shape.dropFirst(), baseArray: [Element](allElements) + [Element](count: shape.dropFirst().reduce(*), repeatedValue: additionalItem))
        // But given all preformance we're leaving on the table elsewhere, it seems silly to break the nice symmetry for an unimportant function.
        // I've also not benchmarked the difference, so this could turn out to be a pessimization, though that would shock me.
    }
    
    /// Returns a DenseArray of a higher order by creating a new first axis. Both input arrays must be the same shape.
    /// e.g.
    ///    1 2 3 4 | 5 6 7 8 --> 1 2 3 4
    ///                          5 6 7 8
    public func laminate<A: Array where A.Element == Element>(additionalItems: A) -> ComputedArray<Element> {
        guard shape == additionalItems.shape else {
            fatalError("Arrays must have same shape to be laminated")
        }
        let left = ComputedArray(self)
        let right = ComputedArray(additionalItems) // type erase both so we can put them in an array.
        return ([left, right] as [ComputedArray<Element>]).ravel().disclose()
    }
    
    /// Returns a DenseArray of a higher order by creating a new last axis. Both input arrays must be the same shape.
    /// e.g.
    ///    1 2 3 4 | 5 6 7 8 --> 1 5
    ///                          2 6
    ///                          3 7
    ///                          4 8
    public func interpose<A: Array where A.Element == Element>(additionalItems: A) -> ComputedArray<Element> {
        guard shape == additionalItems.shape else {
            fatalError("Arrays must have same shape to be interposed")
        }
        let left = ComputedArray(self)
        let right = ComputedArray(additionalItems) // type erase both so we can put them in an array.
        return ([left, right] as [ComputedArray<Element>]).ravel().discloseFirst()
    }
    
}

public extension Array where Element: Array {
    
    func discloseEager() -> ComputedArray<Element.Element> {
        let newShape = shape + self.allElements.first!.shape
        let baseArray = self.allElements.flatMap { $0.allElements }
        return ComputedArray(DenseArray(shape: newShape, baseArray: baseArray))
    }
    
    func disclose() -> ComputedArray<Element.Element> {
        let newShape = shape + self.allElements.first!.shape
        return ComputedArray(shape: newShape, cartesian: { indices in
            let subArray = self[[Int](indices[0..<self.rank])]
            return subArray[[Int](indices[self.rank..<indices.count])]
        })
    }
    
    func discloseFirst() -> ComputedArray<Element.Element> {
        let newShape = self.allElements.first!.shape + shape
        return ComputedArray(shape: newShape, cartesian: { indices in
            let subArray = self[[Int](indices[indices.count - self.rank..<indices.count])]
            return subArray[[Int](indices[0..<indices.count - self.rank])]
        })
    }
    
}

// MARK: - Map, VectorMap, Coordinate
public extension Array {
    
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
    
    /// Returns a sequence containing pairs of cartesian indices and `Element`s.
    public func coordinate() -> AnySequence<([Int], Element)> {
        let indexGenerator = makeRowMajorIndexGenerator(shape)
        
        return AnySequence(AnyGenerator {
            guard let indices = indexGenerator.next() else { return nil }
            return (indices, self[indices]) // TODO: Linear indexing is cheaper for DenseArrays. Consider specializing.
            })
    }
    
}

// MARK: - Rotate, Reduce, Scan, RotateFirst, ReduceFirst, ScanFirst
public extension Array {
    
    /// Returns a DenseArray whose columns are shifted `count` times.
    public func rotate(count: Int) -> ComputedArray<Element> {
        return vectorMap(byRows: true, transform: {$0.rotate(count)})
    }
    
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
    
    /// Returns a DenseArray whose first dimension's elements are shifted `count` times.
    public func rotateFirst(count: Int) -> ComputedArray<Element> {
        return vectorMap(byRows: false, transform: {$0.rotate(count)})
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

// MARK: - Generalized Inner and Outer Products

/// Returns the outer product `transform` of `left` and `right`.
/// The outer product is the result of  all elements of `left` and `right` being `transform`'d.
public func outer<A: Array, B: Array, C>
    (left: A, _ right: B, product: (A.Element, B.Element) -> C) -> ComputedArray<C> {
    return ComputedArray(shape: left.shape + right.shape, cartesian: { indices in
        let l = left[[Int](indices[0..<left.rank])]
        let r = right[[Int](indices[left.rank..<indices.count])]
        return product(l, r) // This one looks a lot slower than the eager version...
    })
}

/// Returns the inner product of `left` and `right`, fused with `transform` and reduced by `combine`.
/// For example the dot product of A & B is defined as `inner(A, B, *, +)`.
public func inner<A: Array, B: Array, C>(left: A, _ right: B, product: (ComputedArray<A.Element>, ComputedArray<B.Element>) -> ComputedArray<C>, sum: (C, C) -> C) -> ComputedArray<C> {
    return outer(left.enclose(left.rank - 1), right.enclose(0), product: product).map { $0.reduce(sum).scalar! }
}

/// Returns the inner product of `left` and `right`, fused with `transform` and reduced by `combine`.
/// For example the dot product of A & B is defined as `inner(A, B, *, 0, +)`.
public func inner<A: Array, B: Array, C, D>(left: A, _ right: B, product: (ComputedArray<A.Element>, ComputedArray<B.Element>) -> ComputedArray<C>, sum: (D, C) -> D, initialSum: D) -> ComputedArray<D> {
    return outer(left.enclose(left.rank - 1), right.enclose(0), product: product).map { $0.reduce(initialSum, combine: sum).scalar! }
}

// MARK: - Multi-Map

/// Returns a ComputedArray with pairs of left's and right's elements at each index.
public func zip<A: Array, B: Array>(left: A, _ right: B) -> ComputedArray<(A.Element, B.Element)> {
    precondition(left.shape == right.shape, "Arrays must have the same shape to zip")
    
    return ComputedArray(shape: left.shape, linear: { (left[linear: $0], right[linear: $0]) })
}

// Currently not exposed as part of the public API. Not sure it's useful for much else.
// Returns an Array with a rank equal to left's and a shape equal to the sums of the shapes (offset by one if byRows = false), whose (row or highest-dimensional) vectors are the output of the transform applied to pairs of left's & right's (row or highest-dimensional) vectors.
//
// Throwing transforms require eagar-ish computation.
func zipVectorMap<A: Array, B: Array, C>(left: A, _ right: B, byRows rowVector: Bool = true, transform: ([A.Element], [B.Element]) throws -> [C]) rethrows -> ComputedArray<C> {
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
    
    func internalZipVectorMap<A: Array, B: Array, C>(left: A, _ right: B, byRows rowVector: Bool = true, transform: ([A.Element], [B.Element]) throws -> [C]) rethrows -> ComputedArray<C> {
        
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
        let partialResults = try zip(slice, rslice).map { try internalZipVectorMap($0.0, $0.1, byRows: rowVector, transform: transform) }.ravel()
        return rowVector ? partialResults.disclose() : partialResults.discloseFirst()
    }
    
    return try ComputedArray(internalZipVectorMap(left, right, byRows: rowVector, transform: transform))
}

// Currently not exposed as part of the public API. Not sure it's useful for much else.
// Returns an Array with a rank equal to left's and a shape equal to the sums of the shapes (offset by one if byRows = false), whose (row or highest-dimensional) vectors are the output of the transform applied to pairs of left's & right's (row or highest-dimensional) vectors.
func zipVectorMap<A: Array, B: Array, C, AA, BB where A.Element == AA, B.Element == BB>(left: A, _ right: B, byRows rowVector: Bool = true, transform: ([AA], [BB]) -> [C]) -> ComputedArray<C> {
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
    let enclosed = zip(enclosedLeft, enclosedRight).map { (l, r) -> ComputedArray<C> in
        let ll = [AA](l.allElements)
        let rr = [BB](r.allElements)
        return transform(ll, rr).ravel()
    }
    return rowVector ? enclosed.disclose() : enclosed.discloseFirst()
}


extension Array {
    
    /// The length of the Array in a particular dimension.
    /// Safe to call without checking the Array's rank (unlike .shape[d])
    func size(d: Int) -> Int {
        return d < rank ? shape[d] : 1
    }
    
    /// The length of the Array in several dimensions.
    /// Safe to call without checking the Array's rank (unlike .shape[d])
    func size(ds: [Int]) -> [Int] {
        return ds.map(size)
    }
    
}
