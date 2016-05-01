// Copyright 2016 The Shear Authors. All rights reserved.
// Use of this source code is governed by a MIT-style
// license that can be found in the LICENSE file.

import Foundation

public struct ArraySlice<T>: Array {
    
    // MARK: - Associated Types
    
    public typealias Element = T
    
    // MARK: - Underlying Storage
    
    /// A type-erased array that serves as the underlying backing storage for this `ArraySlice`.
    private var storage: ComputedArray<Element>
    
    /// The Swift.Array of `ArrayIndex` that define the view into `storage`.
    private let viewIndices: [ArrayIndex]
    
    /// If an ArraySlice's view is single-valued in one dimension, this array holds that value.
    private let compactedView: [Int?]
    
    // MARK: - Stored Properties
    
    public let shape: [Int]
    
    /// The stride needed to index into storage.
    private let stride: [Int]
    
}

// MARK: - Initializers
extension ArraySlice {
    
    /// Construct a ArraySlice from a complete view into `baseArray`.
    init<A: Array where A.Element == Element>(baseArray: A) {
        self.init(baseArray: baseArray, viewIndices: [ArrayIndex](count: baseArray.rank, repeatedValue: ArrayIndex.All))
    }
    
    /// Construct a ArraySlice from a partial view into `baseArray` as mediated by the `viewIndices`.
    init<A: Array where A.Element == Element>(baseArray: A, viewIndices: [ArrayIndex]) {
        guard let shapeAndCompactedView = makeShape(baseArray.shape, view: viewIndices) else {
            fatalError("Invalid bounds for an ArraySlice")
        }
        
        self.storage = ComputedArray(baseArray)
        self.shape = shapeAndCompactedView.shape
        self.compactedView = shapeAndCompactedView.compactedView
        self.viewIndices = viewIndices
        self.stride = calculateStride(shape)
    }
    
    /// Construct a ArraySlice from a complete view into `baseArray`.
    init(baseArray: ArraySlice<Element>) {
        self.init(baseArray: baseArray, viewIndices: [ArrayIndex](count: baseArray.rank, repeatedValue: ArrayIndex.All))
    }
    
    /// Construct a ArraySlice from a partial view into `baseArray` as mediated by the `viewIndices`.
    init(baseArray: ArraySlice<Element>, viewIndices: [ArrayIndex]) {
        let absoluteViewIndices = transformToAbsoluteViewIndices(baseArray, view: viewIndices)
        self.init(baseArray: baseArray.storage, viewIndices: absoluteViewIndices)
    }
    
}

// MARK: - All Elements Views
extension ArraySlice {
    
    public var allElements: AnyRandomAccessCollection<Element> {
        return AnyRandomAccessCollection(AllElementsCollection(array: self))
    }
    
    public subscript(linear linearIndex: Int) -> Element {
        return self[linearToCartesianIndices(linearIndex)]
    }
    
    private func linearToCartesianIndices(index: Int) -> [Int] {
        var index = index
        return stride.map { s in
            let i: Int
            (i, index) = (index / s, index % s)
            return i
        }
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
        return zip(compactedView, viewIndices).map {
            if let d = $0 { return d }
            return convertIndex(g.next()!, view: $1)
        }
    }
    
    public subscript(indices: [Int]) -> Element {
        let storageIndices = getStorageIndices(indices)
        return storage[storageIndices]
    }
    
    public subscript(indices: Int...) -> Element {
        let storageIndices = getStorageIndices(indices)
        return storage[storageIndices]
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

// TODO: Make these less ugly.

private func makeShape(baseShape: [Int], view: [ArrayIndex]) -> (shape: [Int], compactedView: [Int?])? {
    // Assumes view is within bounds.
    func calculateBound(baseCount: Int, view: ArrayIndex) -> Int {
        switch view {
        case .All: return baseCount
        case .SingleValue: return 1
        case .List(let list): return list.count
        case .Range(let low, let high): return high - low
        }
    }
    
    func calculateUncompactedShape(baseShape: [Int], view: [ArrayIndex]) -> [Int] {
        return zip(baseShape, view).map(calculateBound)
    }
    
    func calculateCompactedBound(baseCount: Int, view: ArrayIndex) -> Int? {
        guard baseCount == 1 else { return nil }
        switch view {
        case .All:
            return 0 // Cannot be reached, as there cannot be singular dimensions in the base array's shape either.
        case .SingleValue(let sv):
            return sv
        case .List(let list):
            return list.first! // If the list is empty we have a problem we should have detected earlier.
        case .Range(let low, _):
            return low
        }
    }
    
    func calculateCompactedView(uncompactedShape: [Int], view: [ArrayIndex]) -> [Int?] {
        return zip(uncompactedShape, view).map(calculateCompactedBound)
    }
    
    // Check for correct number of indices
    guard baseShape.count == view.count else { return nil }
    guard !zip(baseShape, view).map({$1.isInbounds($0)}).contains(false) else { return nil }
    
    let uncompactedShape = calculateUncompactedShape(baseShape, view: view)
    guard !uncompactedShape.contains({$0 < 1}) else { return nil }
    
    let compactedView = calculateCompactedView(uncompactedShape, view: view)
    return (uncompactedShape.filter {$0 != 1}, compactedView)
}

private func convertIndex(index: Int, view: ArrayIndex) -> Int {
    switch view {
    case .All: return index
    case .SingleValue: fatalError("This cannot happen")
    case .List(let list): return list[index]
    case .Range(let low, _): return low + index
    }
}

private func transformToAbsoluteViewIndices<T>(baseSlice: ArraySlice<T>, view: [ArrayIndex]) -> [ArrayIndex] {
    guard baseSlice.shape.count == view.count else { fatalError("Incorrect number of indices to slice array") }
    guard !zip(baseSlice.shape, view).map({$1.isInbounds($0)}).contains(false) else { fatalError("Slice indices are out of bounds") }
    
    var g = view.generate()
    return zip(baseSlice.compactedView, baseSlice.viewIndices).map {
        if let d = $0.0 { return .SingleValue(d) }
        
        switch $0.1 {
        case .All:
            return g.next()! // If the parent slice is .All in a dimension, than the child's ArrayIndex in that dimension is the only constraint
        case .SingleValue:
            return $0.1 // On the other hand, if the parent slice is a .SingleValue, it fully determines the relationship to the base DenseArray
                        // However, this code is actually unreachable because singular dimensions are compressed.
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
