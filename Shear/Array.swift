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
    ///     If the Array represents a 3 by 4 matrix, its shape is [3, 4]
    ///     If the Array is a column vector of 5 elements, its shape is [5, 1]
    ///     If the Array is a row vector of 6 elements, its shape is [1, 6]
    var shape: [Int] { get }
    
    /// A view that provides a `CollectionType` over all the items stored in the array.
    /// The first element is at the all-zeros index of the array. 
    /// Elements thereafter are in row-major ordering.
    var allElements: AnyForwardCollection<Element> { get } // TODO: Consider renaming "elementsView" "flatView" "linearView", something else that makes it clear you lose the position information
    // TODO: we'd prefer the type of allEmements to be a contrainted CollectionType but I'm not sure this currently possible with Swift's typesystem see ElementsView
    // TODO: we want an enumerate()-like function to return ([index], element) pairs
    
    // MARK: - Methods
    
    subscript(indices: Int...) -> Element { get set }
    
    subscript(indices: [Int]) -> Element { get set }

    subscript(indices: ArrayIndex...) -> ArraySlice<Element> { get }
    
    subscript(indices: [ArrayIndex]) -> ArraySlice<Element> { get }

}

// MARK: - Extension Methods
public extension Array {
    
    /// The number of non-unitary demensions of this Array.
    /// e.g.
    ///     If the Array represents a 3 by 4 matrix, its shape is 2
    ///     If the Array is a column vector of 5 elements, its shape is 1
    ///     If the Array is a row vector of 6 elements, its shape is 1
    ///     If the Array is the Empty Array, its shape is 0
    var rank: Int {
        get {
            if isEmpty { return 0 }
            
            return shape.filter {$0 != 1}.count
        }
    }
    
    /// Returns true iff `self` is empty.
    var isEmpty: Bool {
        return shape.filter {$0 == 0}.count > 0
    }

    /// Returns true iff `self` is scalar.
    var isScalar: Bool {
        return !isEmpty && rank == 0
    }
    
    /// If `self` is a scalar in an Array box, returns the scalar value.
    /// Otherwise returns nil.
    var scalarValue: Element? {
        guard isScalar else { return nil }
        
        return allElements.first
    }
    
    /// Returns true iff `self` is a vector.
    var isVector: Bool {
        return rank == 1
    }
    
    /// Returns true iff `self` is a row vector.
    var isRowVector: Bool {
        return isVector && shape.count == 2 && shape[0] == 1
    }
    
    /// Returns true iff `self` is a column vector.
    var isColumnVector: Bool {
        return isVector && shape.count == 2 && shape[1] == 1
    }
    
}

public extension Array {
    
    func sequence(deminsion: Int) -> [ArraySlice<Element>] {
        guard deminsion < shape.count else { fatalError("An array cannot be sequenced on a deminsion it does not have.") }
        
        let viewIndices = Swift.Array(count: shape.count, repeatedValue: ArrayIndex.All)
        return (0..<shape[deminsion]).map {
            var nViewIndicies = viewIndices
            nViewIndicies[deminsion] = .SingleValue($0)
            return self[viewIndices]
        }
    }
        
    
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