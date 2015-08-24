//
//  ArraySlice.swift
//  Shear
//
//  Created by Andrew Snow on 8/9/15.
//  Copyright © 2015 Andrew Snow. All rights reserved.
//

import Foundation

// There are two hard functions that we need to impliment:
// Cartiasian indexing
// linear indexing
// plus the ability to subslice slices and bounds check all of this...

public struct ArraySlice<T>: Array {
    
    // MARK: - Associated Types
    
    public typealias Element = T
    
    //    public typealias ElementsView = ArraySlice<T>
    
    // MARK: - Underlying Storage
    
    /// The `DenseArray` that serves as the underlying backing storage for this `ArraySlice`.
    private var storage: DenseArray<Element>
    
    /// The Swift.Array of `ArrayIndex` that define the view into `storage`.
    private let viewIndices: [ArrayIndex]
    
    // MARK: - Stored Properties
    
    public let shape: [Int]
    
}

// MARK: - Initializers
extension ArraySlice {
    
    /// Construct a ArraySlice from a complete view into `baseArray`.
    init(baseArray: DenseArray<Element>) {
        self.storage = baseArray
        self.shape = storage.shape
        self.viewIndices = Swift.Array(count: shape.count, repeatedValue: .All)
    }
    
    /// Construct a ArraySlice from a partial view into `baseArray` as mediated by the `viewIndices`.
    init(baseArray: DenseArray<Element>, viewIndices: [ArrayIndex]) {
        guard let shape = makeShapeAndTransform(baseArray.shape, viewIndices: viewIndices) else {
            fatalError("ArraySlice's bounds must be within the DenseArray")
        }
        
        self.storage = baseArray
        self.shape = shape
        self.viewIndices = viewIndices
    }
    
    /// Construct a ArraySlice from a complete view into `baseArray`.
    init(baseArray: ArraySlice<Element>) {
        self.storage = baseArray.storage
        self.shape = baseArray.shape
        self.viewIndices = baseArray.viewIndices
    }
    
    /// Construct a ArraySlice from a partial view into `baseArray` as mediated by the `viewIndices`.
    init(baseArray: ArraySlice<Element>, viewIndices: [ArrayIndex]) {
        guard let shape = makeShapeAndTransform(baseArray.shape, viewIndices: viewIndices) else {
            fatalError("ArraySlice's bounds must be within the ArraySlice")
        }
        
        self.storage = baseArray.storage
        self.shape = shape
        self.viewIndices = viewIndices // WRONG: the viewIndices will contrain the original array not the parent slice's contraints
    }
    
}

// MARK: - All Elements Views
extension ArraySlice {
    
    public var allElements: AnyForwardCollection<Element> {
        // this is super inefficient, but quite easy to impliment.
        let allValidIndices = enumerateAllValuesFromZeroToBounds(shape)
        return AnyForwardCollection(allValidIndices.map {self[$0]})
    }
    
}


// MARK: - Scalar Indexing
extension ArraySlice {
    
    private func getStorageIndices(indices: [Int]) -> [Int] {
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
        
        // Now that we're bounds checked, we can do this knowing we have enough g.next()s & without checking if we'll be within the various arrays
        var g = indices.generate()
        return viewIndices.map {
            switch $0 {
            case .All:
                return g.next()!
            case .SingleValue(let sv):
                return sv
            case .Range(let low, _):
                return low + g.next()!
            case .List(let list):
                return list[g.next()!]
            }
        }
    }
    
    subscript(indices: [Int]) -> Element {
        get {
            let storageIndices = getStorageIndices(indices)
            return storage[storageIndices]
        }
        set (newValue) {
            let storageIndices = getStorageIndices(indices)
            storage[storageIndices] = newValue
        }
    }
    
    public subscript(indices: Int...) -> Element {
        get {
            let storageIndices = getStorageIndices(indices)
            return storage[storageIndices]
        }
        set (newValue) {
            let storageIndices = getStorageIndices(indices)
            storage[storageIndices] = newValue
        }
    }
    
}

// MARK: - Slice Indexing
extension ArraySlice {
    
    subscript(indices: [ArrayIndex]) -> ArraySlice<Element> {
        return ArraySlice(baseArray: self, viewIndices: indices)
    }
    
    public subscript(indices: ArrayIndex...) -> ArraySlice<Element> {
        return ArraySlice(baseArray: self, viewIndices: indices)
    }
    
}

// MARK: - Private Helpers

private func makeShapeAndTransform(initialShape: [Int], viewIndices: [ArrayIndex]) -> [Int]? {
    // Check for correct number of indicies
    guard initialShape.count == viewIndices.count else { return nil }
    
    let pairs = zip(initialShape, viewIndices)
    
    // Bounds check indicies
    guard pairs.map({$1.isInbounds($0)}).filter({$0 == false}).isEmpty else { return nil }
    
    let shape = pairs.flatMap { (initialBound, index) -> Int? in
        switch index {
        case .All:
            return initialBound
        case .SingleValue:
            return nil // Compress shape by removing extranious 1s
        case .List(let list):
            return list.count
        case .Range(let low, let high):
            return high - low
        }
    }
    
    return shape
}

// Ugly functions get ugly names.
// The returned subarrays represent each possible combination of values from 0 to the bound for that place in the initial array.
private func enumerateAllValuesFromZeroToBounds(bounds: [Int]) -> [[Int]] {
    func recursivelyEnumerateAllValuesFromZeroToBounds(remainingBits: Swift.ArraySlice<Int>) -> [[Int]] {
        guard let first = remainingBits.first else { return [[]] }
        
        let results = recursivelyEnumerateAllValuesFromZeroToBounds(remainingBits.dropFirst())
        
        return (0..<first).map { currentIndex -> [[Int]] in
            return results.map { [currentIndex] + $0 }
            }.flatMap {$0}
    }
    
    return recursivelyEnumerateAllValuesFromZeroToBounds(Swift.ArraySlice(bounds))
}
