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
    
    subscript(linear linear: Int) -> Element { get set } // We'd prefer all linear indexing happen via .allElements; however, coaxing .allElements into holding a mutable reference to it's value-typed parent is hard, so for the time being, we're doing this.

}

// MARK: - Basic informational queries
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
    
}

// MARK: - CustomStringConvertible
public extension Array {
    
    public var description: String {
        return toString(Swift.ArraySlice(shape), elementGenerator: allElements.generate())
    }
    
}

// MARK: - Not-Really-Equatable-For-Reasons-Byond-Our-Control
// We could make an optimized version for DenseArrays that compares shape && storage 
// (which can be faster since native arrays can test if they point to the same underlying buffer).
// Likewise, ArraySlices equality could check their underlying DenseArrays for equality which could sometimes get the same optimization.
public func ==<A: Array, B: Array where A.Element == B.Element, A.Element: Equatable>(left: A, right: B) -> Bool {
    return map(left, right, transform: ==).allElements.filter { $0 == false }.isEmpty
}

// When called with the correct args, it returns a string that looks like the nested native array equivalent.
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