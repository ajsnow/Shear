// Copyright 2016 The Shear Authors. All rights reserved.
// Use of this source code is governed by a MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// A protocol defining the interface for all multi-dimensional array.
public protocol TensorProtocol: CustomStringConvertible {
    
    // MARK: - Associated Types
    
    /// The type of elements stored by this `TensorProtocol`.
    associatedtype Element
    
    // MARK: - Properties
    
    /// The shape (length in each demision) of this `TensorProtocol`.
    /// The last element is the count of columns; the first is the count along the `TensorProtocol`'s highest dimension.
    ///
    /// e.g.
    ///     If the Tensor is a 3 by 4 matrix, its shape is [3, 4]
    ///     If the Tensor is a vector of 7 elements, its shape is [7]
    ///     If the Tensor is a scalar, its shape is []
    ///     If the Tensor is empty, its shape is also []
    var shape: [Int] { get }
    
    /// A view that provides a `CollectionType` over all the items stored in the array.
    ///
    /// The first element is at the all-zeros index of the array.
    /// Elements thereafter are in row-major ordering.
    var allElements: AnyRandomAccessCollection<Element> { get }
    // TODO: Consider renaming "elementsView" "flatView" "linearView", something else that makes it clear you lose the position information
    
    /// Returns true iff TensorProtocol refers to parts of another array or the wholes of multiple other array.
    /// I.e. if there's any reason (decreasing memory usage, improving locality) to realloc the array.
    var unified: Bool { get }
    
    // MARK: - Methods
    
    /// Returns the element for the given set of indices.
    subscript(indices: Int...) -> Element { get }
    
    /// Returns the element for the given set of indices.
    subscript(indices: [Int]) -> Element { get }
    
    /// Returns a `TensorSlice` view into the base `TensorProtocol` determined by the set of `TensorIndex`s.
    subscript(indices: TensorIndex...) -> Tensor<Element> { get }
    
    /// Returns a `TensorSlice` view into the base `TensorProtocol` determined by the set of `TensorIndex`s.
    subscript(indices: [TensorIndex]) -> Tensor<Element> { get }
    
    /// Returns the element for the given linear index.
    subscript(linear linear: Int) -> Element { get }
    
    /// Returns a `TensorSlice` view into the base `TensorProtocol` determined by the range of linear indices.
    subscript(linear indices: Range<Int>) -> Tensor<Element> { get }
    
    /// Returns a sequence containing pairs of cartesian indices and `Element`s.
    func coordinate() -> AnySequence<([Int], Element)>
    
}

// MARK: - Basic informational queries
public extension TensorProtocol {
    
    /// The number of non-unitary demensions of this TensorProtocol.
    ///
    /// e.g.
    ///     If the TensorProtocol represents a 3 by 4 matrix, its rank is 2
    ///     If the TensorProtocol is a vector of 5 elements, its rank is 1
    ///     If the TensorProtocol is a scalar or the Empty TensorProtocol, its rank is 0
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
    
    /// If `self` is a scalar in an TensorProtocol box, returns the scalar value.
    /// Otherwise returns nil.
    var scalar: Element? {
        guard isScalar else { return nil }
        
        return self[]
    }
    
    /// Returns true iff `self` is a vector.
    var isVector: Bool {
        return rank == 1
    }
    
    /// The length of the TensorProtocol in a particular dimension.
    /// Safe to call without checking the Tensor's rank (unlike .shape[d])
    func size(_ d: Int) -> Int {
        return d < rank ? shape[d] : 1
    }
    
    /// The length of the TensorProtocol in several dimensions.
    /// Safe to call without checking the Tensor's rank (unlike .shape[d])
    func size(_ ds: [Int]) -> [Int] {
        return ds.map(size)
    }
    
}

public extension TensorProtocol {
    
    /// Take all of the elements of `Self` into a native array and build a new `Tensor` referencing that array.
    func unify() -> Tensor<Element> {
        return Tensor(shape: shape, values: [Element](allElements))
    }
    
}

// MARK: - Not-Really-Equatable-For-Reasons-Beyond-Our-Control
// We could make an optimized version for DenseTensors that compares shape && storage
// (which can be faster since native arrays can test if they point to the same underlying buffer).
// Likewise, TensorSlices equality could check their masks & underlying DenseTensors for equality which could sometimes get the same optimization.
public func ==<A: TensorProtocol, B: TensorProtocol>(left: A, right: B) -> Bool where A.Element == B.Element, A.Element: Equatable {
    return left.shape == right.shape && !zip(left, right).allElements.contains(where: !=)
}

public func !=<A: TensorProtocol, B: TensorProtocol>(left: A, right: B) -> Bool where A.Element == B.Element, A.Element: Equatable {
    return !(left == right)
}

// MARK: - CustomStringConvertible
public extension TensorProtocol {
    
    public var description: String {
        // We add the A{ ... }  to make it easy to spot nested `Tensors`.
        return "A{" + toString(ArraySlice(shape), elementGenerator: allElements.makeIterator()) + "}"
    }
    
}

// When called with the correct args, it returns a string that looks like the nested native array equivalent.
fileprivate func toString<A>(_ remainingShape: ArraySlice<Int>, elementGenerator: AnyIterator<A>) -> String {
    guard let length = remainingShape.first else {
        return String(describing: elementGenerator.next()!) // If the number of elements is not the scan-product of the shape, something terrible has already happened.
    }
    
    var str = "[" + toString(remainingShape.dropFirst(), elementGenerator: elementGenerator)
    for _ in 1..<length {
        str += ", " + toString(remainingShape.dropFirst(), elementGenerator: elementGenerator)
    }
    str.append(Character("]"))
    return str
}

// In Swift 3.1, recursion inside of nested functions segfaults the compiler.
fileprivate func aplString<A: TensorProtocol>(_ array: A, paddingCount: Int) -> String {
    if array.isVector {
        return array.allElements.map { String(describing: $0).leftpad(paddingCount) }.joined(separator: " ")
    }
    let newlines = String(repeating: "\n", count: array.rank - 1)
    return array.sequenceFirst.map { aplString($0, paddingCount: paddingCount) }.joined(separator: newlines)
}

/// Provides a string similar to the APL printout of a given `TensorProtocol`.
func aplString<A: TensorProtocol>(_ array: A) -> String {
    guard !array.isEmpty else { return "" }
    guard !array.isScalar else { return String(describing: array.scalar!) }
    // I don't think this will handle wide character correctly. Sorry, CJK!
    let paddingCount = array.allElements.lazy.map { String(describing: $0) }.max { $0.characters.count < $1.characters.count }?.characters.count ?? 0
    return aplString(array, paddingCount: paddingCount)
}
