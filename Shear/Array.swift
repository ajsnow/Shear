//
//  Array.swift
//  Sheep
//
//  Created by Andrew Snow on 6/14/15.
//  Copyright © 2015 Andrew Snow. All rights reserved.
//

import Foundation

// MARK: - Requirements
public protocol Array: CustomStringConvertible {
    
    // MARK: - Associated Types
    
    /// The type of element stored by this `Array`.
    typealias Element
    
    //    /// A collection of `Elements` that constitute an `Array`.
    //    typealias ElementsView = CollectionType // TODO: Not as typesafe as I'd like as there's no typecheck that `ElementsView` generates `Elements`
    
    // MARK: - Initializers
    
//    init(shape newShape: [Int], repeatedValue: Element)
//    init(shape newShape: [Int], baseArray: [Element])
//    init<A: Array where A.Element == Element>(shape newShape: [Int], baseArray: A)
    
    // MARK: - Properties
    
    /// The shape (lenght in each demision) of this `Array`.
    /// e.g. 
    ///     If the Array is a 3 by 4 matrix, its shape is [3, 4]
    ///     If the Array is a column vector of 5 elements, its shape is [5, 1]
    ///     If the Array is a row vector of 6 elements, its shape is [1, 6]
    ///     If The Array is a vector of 7 elements, its shape is [7]
    ///     If the Array is a scalar, its shape is []
    ///     The Empty Array has an empty shape or at least one 0 in its shape
    var shape: [Int] { get }
    
    /// A view that provides a `CollectionType` over all the items stored in the array.
    /// The first element is at the all-zeros index of the array. 
    /// Elements thereafter are in row-major ordering.
    var allElements: AnyRandomAccessCollection<Element> { get } // TODO: Consider renaming "elementsView" "flatView" "linearView", something else that makes it clear you lose the position information
    // TODO: we'd prefer the type of allEmements to be a contrainted CollectionType but I'm not sure this currently possible with Swift's typesystem see ElementsView
    // TODO: we want an enumerate()-like function to return ([index], element) pairs
    
    // MARK: - Methods
    
    subscript(indices: Int...) -> Element { get set }
    
    subscript(indices: [Int]) -> Element { get set }

    // In a 3 array: [Depth, Row, Column]
    subscript(indices: ArrayIndex...) -> ArraySlice<Element> { get }
    
    subscript(indices: [ArrayIndex]) -> ArraySlice<Element> { get }

}

// MARK: - Extension Methods
public extension Array {
    
    /// The number of non-unitary demensions of this Array.
    /// e.g.
    ///     If the Array represents a 3 by 4 matrix, its rank is 2
    ///     If the Array is a column vector of 5 elements, its rank is 1
    ///     If the Array is a row vector of 6 elements, its rank is 0
    ///     If the Array is a scalar or the Empty Array, its rank is 0
    var rank: Int {
        if isEmpty { return 0 }
        
        return shape.filter {$0 != 1}.count
    }
    
    /// Returns true iff `self` is empty.
    var isEmpty: Bool {
        return allElements.isEmpty
    }

    /// Returns true iff `self` is scalar.
    var isScalar: Bool {
        return !isEmpty && rank == 0
    }
    
    /// If `self` is a scalar in an Array box, returns the scalar value.
    /// Otherwise returns nil.
    var scalar: Element? {
        guard isScalar else { return nil }
        
        return allElements.first
    }
    
    /// Returns true iff `self` is a vector.
    var isVector: Bool {
        return rank == 1
    }
    
    /// Returns true iff `self` is a row vector.
    var isRowVector: Bool {
        return isVector && shape.count == 2 && shape[1] == 1
    }
    
    /// Returns true iff `self` is a column vector.
    var isColumnVector: Bool {
        return isVector && shape.count == 2 && shape[0] == 1
    }
    
}

public extension Array {
    
    func sequence(deminsion: Int) -> [ArraySlice<Element>] {
//        guard !shape.isEmpty else { return [self[ArrayIndex.All]] }
        guard deminsion < shape.count else { fatalError("An array cannot be sequenced on a deminsion it does not have.") }
        
        let viewIndices = Swift.Array(count: shape.count, repeatedValue: ArrayIndex.All)
        return (0..<shape[deminsion]).map {
            var nViewIndices = viewIndices
            nViewIndices[deminsion] = .SingleValue($0)
            return self[nViewIndices]
        }
    }
    
    var sequenceFirst: [ArraySlice<Element>] {
        return sequence(0)
    }
    
    var sequenceLast: [ArraySlice<Element>] {
        return sequence(shape.count - 1)
    }
    
}

public extension Array {
    public func enclose(axes: Int...) -> DenseArray<ArraySlice<Element>> {
        // Since this algo is recursive, we only check and operate on the head of the list.
        guard let axis = axes.first else { fatalError("ran out of axes") }
        guard axis < shape.count else { fatalError("domain") }
        
        let newShape = Swift.Array(shape.enumerate().lazy.filter { $0.index != axis }.map { $0.element })
        
        let internalIndicesList = makeRowMajorIndexGenerator(newShape).map { newIndices -> [ArrayIndex] in
            var internalIndices = newIndices.map { ArrayIndex.SingleValue($0) }
            internalIndices.insert(.All, atIndex: axis)
            return internalIndices
        }
        
        let subarrays = internalIndicesList.map { self[$0] }
        
        return DenseArray(shape: newShape, baseArray: subarrays)
    }
    
    
    func reduce<Z>(initial: Z, combine: ((Z, Element)-> Z)) -> DenseArray<Z> {
        if let s = scalar {
            return DenseArray(shape: [], baseArray: [combine(initial, s)])
        }
        
        let slice = sequenceLast
        guard slice.first?.scalar != nil else {
            return DenseArray(collection: DenseArray(collection: slice.map { $0.reduce(initial, combine: combine) }).sequenceLast)
        }
        
        let result = slice.map { $0.scalar! }.reduce(initial, combine: combine)
        return DenseArray(shape: [], baseArray: [result])
    }
}

public func outer<T, Z, A: Array, B: Array where A.Element == T, B.Element == T>
    (left: A, _ right: B, _ transform: ((T, T) -> Z)) -> DenseArray<Z> {
        var baseArray = Swift.Array<Z>()
        baseArray.reserveCapacity(Int(left.allElements.count * right.allElements.count))
        
        for l in left.allElements {
            for r in right.allElements {
                baseArray.append(transform(l, r))
            }
        }
        
        return DenseArray(shape: left.shape + right.shape, baseArray: baseArray)
}

public func inner<T, Y, Z, A: Array, B: Array where A.Element == T, B.Element == T>
    (left: A, right: B, transform: ((ArraySlice<T>, ArraySlice<T>) -> DenseArray<Y>), initial: Z, combine: ((Z, Y) -> Z)) -> DenseArray<Z> {
        let cA = left.enclose(left.shape.count - 1)
        let cB = right.enclose(0)
        
        let op = outer(cA, cB, transform)
        let baseArray = op.allElements.map{ $0.reduce(initial, combine: combine).allElements.map {$0} }.flatMap {$0}
        return DenseArray(shape: op.shape, baseArray: baseArray)
}

public extension Array {
    
    // I imagine this could simplify comparing shape appropraiteness, but don't actually know if they're that useful.
    
    // The length of the Array in a particular dimension
    func size(d: Int) -> Int {
        return d < shape.count ? shape[d] : 1
    }
    
    // The length of the Array in several dimensions
    func size(ds: [Int]) -> [Int] {
        return ds.map(size)
    }
    
}

// MARK: - Pretty Printing
extension Array {
    
    public var description: String {
        return toString(Swift.ArraySlice(shape), elementGenerator: allElements.generate())
    }
    
}

private func toString<T>(remainingShape: Swift.ArraySlice<Int>, elementGenerator: AnyGenerator<T>) -> String {
    guard let length = remainingShape.first else {
        return String(elementGenerator.next()!) // If the number of elements is not the scan-product of the shape, something terrible has already happened.
    }
    
    var str = "[" + toString(remainingShape.dropFirst(), elementGenerator: elementGenerator)
    for _ in 1..<length {
        str += ", " + toString(remainingShape.dropFirst(), elementGenerator: elementGenerator)
    }
    str.append(Character("]"))
    return str
}