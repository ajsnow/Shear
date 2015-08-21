//
//  DenseArray.swift
//  Sheep
//
//  Created by Andrew Snow on 7/11/15.
//  Copyright © 2015 Andrew Snow. All rights reserved.
//

import Foundation

public struct DenseArray<T>: Array {
    
    // MARK: - Associated Types
    
    /// The type of element stored by this `$TypeName`.
    public typealias Element = T
    
//    public typealias ElementsView = [T]
    
    // MARK: - Underlying Storage
    
    /// The flat builtin array that serves as the underlying backing storage for this `$TypeName`.
    private var storage: [T]
    
    // MARK: - Properties
    
    /// The shape (lenght in each demision) of this `$TypeName`.
    /// e.g. If the `$TypeName` represents a 3 by 4 matrix, it's shape is [3,4]
    public let shape: [Int]
    
    /// The offsets needed to index into storage.
    let offsets: [Int] // Shape is constant; this will need to change when that changes.
    // Dynamic version. If we let shape change, we'll need to make this effeicent by only calling on didSet shape
    //    private var offsets: [Int] {
    //        return Array(shape.scan(1, combine: *)[0..<rank])
    //    }
}

// MARK: - Initializers
public extension DenseArray {
    
    /// Construct a DenseArray with a `shape` of elements, each initialized to `repeatedValue`.
    public init(shape newShape: [Int], repeatedValue: Element) {
        if newShape.isEmpty {
            fatalError("Array must have non-empty shape")
        }
        
        for dimensionLenght in newShape {
            if dimensionLenght <= 0 {
                fatalError("Array must have positive length dimensions")
            }
        }
        
        shape = newShape
        offsets = calculateOffsets(shape)
        let count = shape.reduce(1, combine: *)
        storage = Swift.Array<T>(count: count, repeatedValue: repeatedValue)
    }
    
    /// Reshape a one-dimensional, built-in `baseArray` into a DenseArray of `shape`.
    public init(shape newShape: [Int], baseArray: [Element]) {
        shape = newShape
        offsets = calculateOffsets(shape)
        let count = shape.reduce(1, combine: *)
        
        if count != baseArray.count {
            let wrongness = count > baseArray.count ? "few" : "many"
            fatalError("baseArray has too \(wrongness) elements to construct an array of that shape")
        }
        
        storage = baseArray
    }
    
    /// Reshape any Array `baseArray` into a new DenseArray of `shape`. This iterates over the entire `baseArray` and thus could be quite slow.
    public init<A: Array where A.Element == Element>(shape newShape: [Int], baseArray: A) {
        self.init(shape: newShape, baseArray: baseArray.allElements.map {$0})
    }
    
    /// Reshape a DenseArray `baseArray` into a new DenseArray of `shape`.
    public init(shape newShape: [Int], baseArray: DenseArray<Element>) {
        self.init(shape: newShape, baseArray: baseArray.storage)
    }
    
    /// Reshape a one-dimensional collection type into
    
    /// Construct a DenseArray from a `collection` of DenseArrays.
    public init<C: CollectionType where
        C.Generator.Element == DenseArray<Element>,
        C.Index.Distance == Int>
        (collection: C) {
            if collection.isEmpty {
                fatalError("Cannot construct an Array from empty collection: can't infer shape")
            }
            
            
            let typeCheckerTemp = collection.first! // As of Xcode 7b3, the type checker crashes in the compact version of these lines.
            let firstShape = typeCheckerTemp.shape
            
            if collection.contains({ $0.shape != firstShape }) {
                fatalError("Arrays in the collection constructor must have the same shape")
            }
            
            
            shape = firstShape + [collection.count]
            offsets = calculateOffsets(shape)
            var emptyReserve: [Element] = []
            emptyReserve.reserveCapacity(collection.first!.storage.count * collection.count) // Pre-allocate our big array so that the reduce doesn't need collection.count reallocations
            storage = collection.reduce(emptyReserve, combine: {$0 + $1.storage})
    }
    
    public init(_ tuple: DenseArray<Element>...) {
        self.init(collection: tuple)
    }
}

// MARK: - ArrayLiteralConvertible
// ArrayLiteralConvertible _not_ supported because there is no way to convert an array of (...) arrays to a `$TypeName`.
// The vector case isn't terribly useful.
//extension MyArray: ArrayLiteralConvertible {
//}

// MARK: - Init from Array (of Array (...)) of Elements
extension DenseArray {
    
    init(array: [Element]) {
        shape = [array.count]
        offsets = calculateOffsets(shape)
        storage = array
    }
    
    init(array: [[Element]]) { // Need to assert that the count of sub-arrays are equal
        shape = [array.count, array.first!.count]
        offsets = calculateOffsets(shape)
        storage = array.flatMap { $0 }
    }
    
    init(array: [[[Element]]]) { // Need to assert that the count of sub-arrays are equal
        shape = [array.count, array.first!.count, array.first!.first!.count]
        offsets = calculateOffsets(shape)
        storage = array.flatMap { $0 }.flatMap { $0 }
    }
    
}

// MARK: - All Elements Views
extension DenseArray {
    
    public var allElements: AnyForwardCollection<Element> {
        return AnyForwardCollection(storage)
    }
    
    //enumerate view that has indexes
}

// MARK: - Scalar Indexing
extension DenseArray {
    
    func getStorageIndex(indices: [Int]) -> Int {
        // First, we check to see if we have the right number of indices to address an element:
        if indices.count != rank {
            fatalError("Array indices don't match array shape")
        }
        
        // Next, we check to see if all the indices are between 0 and the count of their demension:
        for (index, count) in zip(indices, shape) {
            if index < 0 || index >= count {
                fatalError("Array index out of range")
            }
        }
        
        // We've meet our preconditions, so lets calculate the target index:
        return zip(indices, offsets).map(*).reduce(0, combine: +) // Aside: clever readers may notice that this is the dot product of the indices and offsets vectors.
    }
    
    subscript(indices: [Int]) -> Element {
        get {
            let storageIndex = getStorageIndex(indices)
            return storage[storageIndex]
        }
        set(newValue) {
            let storageIndex = getStorageIndex(indices)
            storage[storageIndex] = newValue
        }
    }
    
    public subscript(indices: Int...) -> Element {
        get {
            let storageIndex = getStorageIndex(indices)
            return storage[storageIndex]
        }
        set(newValue) {
            let storageIndex = getStorageIndex(indices)
            storage[storageIndex] = newValue
        }
    }

}

// MARK: - ArraySlice Indexing
extension DenseArray {
    subscript(indices: [ArrayIndex]) -> DenseArraySlice<Element> {
        guard let slice = DenseArraySlice(baseArray: self, viewIndices: indices) else { fatalError("Array subscript invalid") }
        
        return slice
    }
    
    public subscript(indices: ArrayIndex...) -> DenseArraySlice<Element> {
        guard let slice = DenseArraySlice(baseArray: self, viewIndices: indices) else { fatalError("Array subscript invalid") }
        
        return slice
    }
}

// MARK: - Private Helpers

// Offsets for column-major ordering (last dimension on n-arrays)
private func calculateOffsets(shape: [Int]) -> [Int] {
    var offsets = shape.scan(1, combine: *)
    offsets.removeLast()
    return offsets
}

// Offsets for row-major ordering (first dimension on n-arrays)
private func calculateOffsetsReverse(shape: [Int]) -> [Int] {
    var offsets: [Int] = shape.reverse().scan(1, combine: *)
    offsets.removeLast()
    return offsets.reverse()
}

private extension SequenceType {
    
    /// Return the array of partial results of repeatedly calling `combine` with an
    /// accumulated value initialized to `initial` and each element of
    /// `self`, in turn, i.e. return
    /// `[initial, combine(results[0], self[0]),...combine(results[count-1], self[count-1]]`.
    func scan<T>(initial: T, @noescape combine: (T, Self.Generator.Element) -> T) -> [T] {
        var results: Swift.Array<T> = [initial]
        for (i, v) in self.enumerate() {
            results.append(combine(results[i], v))
        }
        return results
    }
    
}