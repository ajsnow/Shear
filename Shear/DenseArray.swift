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
    
    public typealias Element = T
    
    // MARK: - Underlying Storage
    
    /// The flat builtin array that serves as the underlying backing storage for this `$TypeName`.
    private var storage: [T]
    
    // MARK: - Stored Properties
    
    public let shape: [Int]
    
    /// The stride needed to index into storage.
    private let stride: [Int]

}

// MARK: - Initializers
extension DenseArray {
    
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
        stride = calculateStride(shape)
        let count = shape.reduce(1, combine: *)
        storage = Swift.Array<T>(count: count, repeatedValue: repeatedValue)
    }
    
    /// Reshape a one-dimensional, built-in `baseArray` into a DenseArray of `shape`.
    public init(shape newShape: [Int], baseArray: [Element]) {
        shape = newShape
        stride = calculateStride(shape)
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
    
    /// Construct a DenseArray from a `collection` of DenseArrays.
    public init<C: CollectionType, A: Array where
        A.Element == Element,
        C.Generator.Element == A,
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
            stride = calculateStride(shape)
            var emptyReserve: [Element] = []
            emptyReserve.reserveCapacity(Int(collection.first!.allElements.count) * collection.count) // Pre-allocate our big array so that the reduce doesn't need collection.count reallocations
            storage = collection.reduce(emptyReserve, combine: {$0 + $1.allElements})
    }
    
    /// Concatonate several DenseArrays.
    public init(_ arrays: DenseArray<Element>...) {
        self.init(collection: arrays)
    }
}

// MARK: - Init from Array (of Array (...)) of Elements
extension DenseArray {
    
    init(array: [Element]) {
        shape = [array.count]
        stride = calculateStride(shape)
        storage = array
    }
    
    init(array: [[Element]]) { // Need to assert that the count of sub-arrays are equal
        shape = [array.count, array.first!.count]
        stride = calculateStride(shape)
        storage = array.flatMap { $0 }
    }
    
    init(array: [[[Element]]]) { // Need to assert that the count of sub-arrays are equal
        shape = [array.count, array.first!.count, array.first!.first!.count]
        stride = calculateStride(shape)
        storage = array.flatMap { $0 }.flatMap { $0 }
    }
    
}

// MARK: - All Elements Views
extension DenseArray {
    
    public var allElements: AnyRandomAccessCollection<Element> {
        return AnyRandomAccessCollection(storage)
    }
    
    //enumerate()-like view that has indexes
    
    public subscript(linear linearIndex: Int) -> Element {
        get {
            return storage[linearIndex]
        }
        set (newValue) {
            storage[linearIndex] = newValue
        }
    }
    
}

// MARK: - Scalar Indexing
extension DenseArray {
    
    func getStorageIndex(indices: [Int]) -> Int {
        // First, we check to see if we have the right number of indices to address an element:
        if indices.count != shape.count {
            fatalError("Array indices don't match array shape")
        }
        
        // Next, we check to see if all the indices are between 0 and the count of their demension:
        for (index, count) in zip(indices, shape) {
            if index < 0 || index >= count {
                fatalError("Array index out of range")
            }
        }
        
        // We've meet our preconditions, so lets calculate the target index:
        return zip(indices, stride).map(*).reduce(0, combine: +) // Aside: clever readers may notice that this is the dot product of the indices and stride vectors.
    }
    
    public subscript(indices: [Int]) -> Element {
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

// MARK: - Slice Indexing
extension DenseArray {
    
    public subscript(indices: [ArrayIndex]) -> ArraySlice<Element> {
        return ArraySlice(baseArray: self, viewIndices: indices)
    }
    
    public subscript(indices: ArrayIndex...) -> ArraySlice<Element> {
        return ArraySlice(baseArray: self, viewIndices: indices)
    }

}
