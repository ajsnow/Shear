// Copyright 2016 The Shear Authors. All rights reserved.
// Use of this source code is governed by a MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// A protocol defining the interface for all multi-dimensional array.
public protocol TensorProtocol: CustomStringConvertible {
    
    // MARK: - Associated Types
    
    /// The type of elements stored by this `TensorProtocol`.
    associatedtype Element
    
    // /// The type of a linear view of the elements stored by this `TensorProtocol`.
    // // TODO: As of Swift 2.2, we cannot contrain the CollecitonType's Element to be the same as the Tensor's Element. According to the mailing list, this ability will land in Swift 3
    // associatedtype ElementsView: CollectionType
    
    // MARK: - Properties
    
    /// The shape (length in each demision) of this `TensorProtocol`.
    /// The last element is the count of columns; the first is the count along the `TensorProtocol`'s highest dimension.
    ///
    /// e.g.
    ///     If the TensorProtocol is a 3 by 4 matrix, its shape is [3, 4]
    ///     If The TensorProtocol is a vector of 7 elements, its shape is [7]
    ///     If the TensorProtocol is a scalar, its shape is []
    ///     If the TensorProtocol is empty, its shape is also []
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
    
    /// Returns an `TensorSlice` view into the base `TensorProtocol` determined by the set of `TensorIndex`s.
    subscript(indices: TensorIndex...) -> TensorSlice<Element> { get }
    
    /// Returns an `TensorSlice` view into the base `TensorProtocol` determined by the set of `TensorIndex`s.
    subscript(indices: [TensorIndex]) -> TensorSlice<Element> { get }
    
    /// Returns the element for the given linear index.
    subscript(linear linear: Int) -> Element { get }
    
    /// Returns a sequence containing pairs of cartesian indices and `Element`s.
    func coordinate() -> AnySequence<([Int], Element)>
    
}

public protocol MutableTensorProtocol: TensorProtocol {
    
    /// Returns the element for the given set of indices.
    subscript(indices: Int...) -> Element { get set }
    
    /// Returns the element for the given set of indices.
    subscript(indices: [Int]) -> Element { get set }
    
    /// Returns the element for the given linear index.
    subscript(linear linear: Int) -> Element { get set }
    
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
        
        return allElements.first
    }
    
    /// Returns true iff `self` is a vector.
    var isVector: Bool {
        return rank == 1
    }
    
    /// The length of the TensorProtocol in a particular dimension.
    /// Safe to call without checking the Tensor's rank (unlike .shape[d])
    func size(d: Int) -> Int {
        return d < rank ? shape[d] : 1
    }
    
    /// The length of the TensorProtocol in several dimensions.
    /// Safe to call without checking the Tensor's rank (unlike .shape[d])
    func size(ds: [Int]) -> [Int] {
        return ds.map(size)
    }
    
}

public extension TensorProtocol {
    
    func unify() -> Tensor<Element> {
        return Tensor(shape: shape, values: [Element](allElements))
    }
    
}

// MARK: - Not-Really-Equatable-For-Reasons-Beyond-Our-Control
// We could make an optimized version for DenseTensors that compares shape && storage
// (which can be faster since native arrays can test if they point to the same underlying buffer).
// Likewise, TensorSlices equality could check their masks & underlying DenseTensors for equality which could sometimes get the same optimization.
public func ==<A: TensorProtocol, B: TensorProtocol where A.Element == B.Element, A.Element: Equatable>(left: A, right: B) -> Bool {
    return left.shape == right.shape && zip(left, right).map(==).allElements.filter { $0 == false }.isEmpty
}

public func !=<A: TensorProtocol, B: TensorProtocol where A.Element == B.Element, A.Element: Equatable>(left: A, right: B) -> Bool {
    return !(left == right)
}

// MARK: - CustomStringConvertible
public extension TensorProtocol {
    
    public var description: String {
        // We add the A{ ... }  to make it easy to spot nested `Tensors`.
        return "A{" + toString(Swift.ArraySlice(shape), elementGenerator: allElements.generate()) + "}"
    }
    
}

// When called with the correct args, it returns a string that looks like the nested native array equivalent.
private func toString<A>(remainingShape: Swift.ArraySlice<Int>, elementGenerator: AnyGenerator<A>) -> String {
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

/// Provides a string similar to the APL printout of a given `TensorProtocol`.
func aplString<A: TensorProtocol>(array: A) -> String {
    guard !array.isEmpty else { return "" }
    guard !array.isScalar else { return String(array.scalar!) }
    
    func aplString<A: TensorProtocol>(array: A, paddingCount: Int) -> String {
        if array.isVector {
            return array.allElements.map { String($0).leftpad(paddingCount) }.joinWithSeparator(" ")
        }
        let newlines = String(count: array.rank - 1, repeatedValue: "\n" as Character)
        return array.sequenceFirst.map { aplString($0, paddingCount: paddingCount) }.joinWithSeparator(newlines)
    }
    
    // I don't think this will handle wide character correctly. Sorry, CJK!
    let paddingCount = array.allElements.lazy.map { String($0) }.maxElement { $0.characters.count < $1.characters.count }?.characters.count ?? 0
    return aplString(array, paddingCount: paddingCount)
}
