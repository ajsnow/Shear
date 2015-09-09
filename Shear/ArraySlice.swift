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
    
    /// If an ArraySlice's view is single-valued in one dimension, this array holds that value.
    private let compactedView: [Int?]
    
    // MARK: - Stored Properties
    
    public let shape: [Int]
    
}

// MARK: - Initializers
extension ArraySlice {
    
    /// Construct a ArraySlice from a complete view into `baseArray`.
    init(baseArray: DenseArray<Element>) {
        self = ArraySlice(baseArray: baseArray, viewIndices: Swift.Array(count: baseArray.shape.count, repeatedValue: ArrayIndex.All))
    }
    
    /// Construct a ArraySlice from a partial view into `baseArray` as mediated by the `viewIndices`.
    init(baseArray: DenseArray<Element>, viewIndices: [ArrayIndex]) {
        guard let shapeAndCompactedView = makeShape(baseArray.shape, viewIndices: viewIndices) else {
            fatalError("ArraySlice's bounds must be within the DenseArray")
        }
        
        self.storage = baseArray
        self.shape = shapeAndCompactedView.shape
        self.compactedView = shapeAndCompactedView.compactedView
        self.viewIndices = viewIndices
    }
    
    /// Construct a ArraySlice from a complete view into `baseArray`.
    init(baseArray: ArraySlice<Element>) {
        self = ArraySlice(baseArray: baseArray, viewIndices: Swift.Array(count: baseArray.shape.count, repeatedValue: ArrayIndex.All))
    }
    
    /// Construct a ArraySlice from a partial view into `baseArray` as mediated by the `viewIndices`.
    init(baseArray: ArraySlice<Element>, viewIndices: [ArrayIndex]) {
        let absoluteViewIndices = transformToAbsoluteViewIndices(baseArray, viewIntoSlice: viewIndices)
        self = ArraySlice(baseArray: baseArray.storage, viewIndices: absoluteViewIndices)
    }
    
}

// MARK: - All Elements Views
extension ArraySlice {
    
    public var allElements: AnyForwardCollection<Element> {
        // this is super inefficient, but quite easy to implement.
        let allValidIndices = enumerateAllValuesFromZeroToBounds(shape)
        return AnyForwardCollection(allValidIndices.map {self[$0]})
    }
    
}


// MARK: - Scalar Indexing
extension ArraySlice {
    
    private func getStorageIndices(indices: [Int]) -> [Int] {
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
        
        // Now that we're bounds checked, we can do this knowing we have enough g.next()s & without checking if we'll be within the various arrays
        var g = indices.generate()
        return zip(compactedView, viewIndices).map {
            if let d = $0.0 { return d }
            
            switch $0.1 {
            case .All:
                return g.next()!
            case .SingleValue(let sv):
                return sv + g.next()!
            case .Range(let low, _):
                return low + g.next()!
            case .List(let list):
                return list[g.next()!]
            }
        }
    }
    
    public subscript(indices: [Int]) -> Element {
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
    
    public subscript(indices: [ArrayIndex]) -> ArraySlice<Element> {
        return ArraySlice(baseArray: self, viewIndices: indices)
    }
    
    public subscript(indices: ArrayIndex...) -> ArraySlice<Element> {
        return ArraySlice(baseArray: self, viewIndices: indices)
    }
    
}

// MARK: - Private Helpers

private func makeShape(initialShape: [Int], viewIndices: [ArrayIndex]) -> (shape: [Int], compactedView: [Int?])? {
    // Check for correct number of indices
    guard initialShape.count == viewIndices.count else { return nil }
    
    let pairs = zip(initialShape, viewIndices)
    
    // Bounds check indices
    guard pairs.map({$1.isInbounds($0)}).filter({$0 == false}).isEmpty else { return nil }
    
    let shape = pairs.map { (initialBound, index) -> Int in
        switch index {
        case .All:
            return initialBound
        case .SingleValue:
            return 1
        case .List(let list):
            return list.count // need to handle zeros
        case .Range(let low, let high):
            return high - low // need to handle zeros
        }
    }
    
    let compactedView = zip(shape, viewIndices).map { (bound, index) -> Int? in
        guard bound == 1 else { return nil }
        switch index {
        case .All:
            return 0
        case .SingleValue(let sv):
            return sv
        case .List(let list):
            return list.first
        case .Range(let low, _):
            return low
        }
    }
    
    return (shape.filter {$0 != 1}, compactedView)
}

private func transformToAbsoluteViewIndices<T>(baseSlice: ArraySlice<T>, viewIntoSlice: [ArrayIndex]) -> [ArrayIndex] {
    // We've already checked that the relative lengths are correct when we checked the viewIntoSlice in makeShape
    
    var g = viewIntoSlice.generate()
    return zip(baseSlice.compactedView, baseSlice.viewIndices).map {
        if let d = $0.0 { return .SingleValue(d) }
        
        switch $0.1 {
        case .All:
            return g.next()! // If the parent slice is .All in a dimension, than the child's ArrayIndex in that dimension is the only constraint
        case .SingleValue:
            return $0.1 // On the other hand, if the parent slice is a .SingleValue, it fully determines the relationship to the base DenseArray
        case .List(let list):
            switch g.next()! {
            case .All:
                return $0.1
            case .SingleValue(let sv):
                return .SingleValue(list[sv])
            case .List(let littleList):
                return .List(littleList.map {list[$0]})
            case .Range(let littleLow, let littleHigh):
                return .List((littleLow..<littleHigh).map {list[$0]})
            }
        case .Range(let low, _):
            switch g.next()! {
            case .All:
                return $0.1
            case .SingleValue(let sv):
                return .SingleValue(low + sv)
            case .List(let littleList):
                return .List(littleList.map {low + $0})
            case .Range(let littleLow, let littleHigh):
                return .Range(low + littleLow, low + littleHigh)
            }
        }
    }
}

// Ugly functions get ugly names.
// The returned subarrays represent each possible combination of values from 0 to the bound for that place in the initial array.
private func enumerateAllValuesFromZeroToBounds(bounds: [Int]) -> [[Int]] {
    func recursivelyEnumerateAllValuesFromZeroToBounds(bounds: Swift.ArraySlice<Int>) -> [[Int]] {
        guard let first = bounds.first else { return [[]] }
        
        let results = recursivelyEnumerateAllValuesFromZeroToBounds(bounds.dropFirst())
        
        return (0..<first).map { currentIndex -> [[Int]] in
            return results.map { [currentIndex] + $0 }
            }.flatMap {$0}
    }
    
    return recursivelyEnumerateAllValuesFromZeroToBounds(Swift.ArraySlice(bounds))
}
