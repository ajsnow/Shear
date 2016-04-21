// Copyright 2016 The Shear Authors. All rights reserved.
// Use of this source code is governed by a MIT-style
// license that can be found in the LICENSE file.

import Foundation

// MARK: - Requirements
public protocol Array: CustomStringConvertible {
    
    // MARK: - Associated Types
    
    /// The type of elements stored by this `Array`.
    associatedtype Element
    
    // /// The type of a linear view of the elements stored by this `Array`.
    // // TODO: As of Swift 2.2, we cannot contrain the CollecitonType's Element to be the same as the Array's Element. According to the mailing list, this ability will land in Swift 3
    // associatedtype ElementsView: CollectionType
    
    // MARK: - Properties
    
    /// The shape (length in each demision) of this `Array`. 
    /// The last element is the count of columns; the first is the count along the `Array`'s highest dimension.
    /// e.g. 
    ///     If the Array is a 3 by 4 matrix, its shape is [3, 4]
    ///     If The Array is a vector of 7 elements, its shape is [7]
    ///     If the Array is a scalar, its shape is []
    ///     If the Array is empty, its shape is also []
    var shape: [Int] { get }
    
    /// A view that provides a `CollectionType` over all the items stored in the array.
    /// The first element is at the all-zeros index of the array. 
    /// Elements thereafter are in row-major ordering.
    var allElements: AnyRandomAccessCollection<Element> { get }
    // TODO: Consider renaming "elementsView" "flatView" "linearView", something else that makes it clear you lose the position information
    
    // MARK: - Methods
    
    subscript(indices: Int...) -> Element { get set }
    
    subscript(indices: [Int]) -> Element { get set }

    subscript(indices: ArrayIndex...) -> ArraySlice<Element> { get }
    
    subscript(indices: [ArrayIndex]) -> ArraySlice<Element> { get }
    
    subscript(linear linear: Int) -> Element { get set }
    
    func enumerate() -> AnySequence<([Int], Element)>

}

// MARK: - Basic informational queries
public extension Array {
    
    /// The number of non-unitary demensions of this Array.
    /// e.g.
    ///     If the Array represents a 3 by 4 matrix, its rank is 2
    ///     If the Array is a vector of 5 elements, its rank is 1
    ///     If the Array is a scalar or the Empty Array, its rank is 0
    var rank: Int {
        return shape.count
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

// MARK: - Not-Really-Equatable-For-Reasons-Beyond-Our-Control
// We could make an optimized version for DenseArrays that compares shape && storage
// (which can be faster since native arrays can test if they point to the same underlying buffer).
// Likewise, ArraySlices equality could check their masks & underlying DenseArrays for equality which could sometimes get the same optimization.
public func ==<A: Array, B: Array where A.Element == B.Element, A.Element: Equatable>(left: A, right: B) -> Bool {
    return left.shape == right.shape && zipMap(left, right, transform: ==).allElements.filter { $0 == false }.isEmpty
}

public func !=<A: Array, B: Array where A.Element == B.Element, A.Element: Equatable>(left: A, right: B) -> Bool {
    return !(left == right)
}

// MARK: - CustomStringConvertible
public extension Array {
    
    public var description: String {
        return "A{" + toString(Swift.ArraySlice(shape), elementGenerator: allElements.generate()) + "}"
    }
    
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