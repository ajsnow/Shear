// Copyright 2016 The Shear Authors. All rights reserved.
// Use of this source code is governed by a MIT-style
// license that can be found in the LICENSE file.

import Foundation

public struct TensorSlice<T>: TensorProtocol {
    
    // MARK: - Associated Types
    
    public typealias Element = T
    
    // MARK: - Underlying Storage
    
    /// A type-erased array that serves as the underlying backing storage for this `TensorSlice`.
    private var storage: Tensor<Element>
    
    /// The Swift.TensorProtocol of `TensorIndex` that define the view into `storage`.
    private let viewIndices: [TensorIndex]
    
    /// If an TensorSlice's view is single-valued in one dimension, this array holds that value.
    private let compactedView: [Int?]
    
    // MARK: - Stored Properties
    
    public let shape: [Int]
    
    public let unified: Bool
    
    /// The stride needed to index into storage.
    private let stride: [Int]
    
}

// MARK: - Initializers
extension TensorSlice {
    
    /// Construct a TensorSlice from a complete view into `baseTensor`.
    init<A: TensorProtocol where A.Element == Element>(baseTensor: A) {
        self.init(baseTensor: baseTensor, viewIndices: [TensorIndex](count: baseTensor.rank, repeatedValue: TensorIndex.All))
    }
    
    /// Construct a TensorSlice from a partial view into `baseTensor` as mediated by the `viewIndices`.
    init<A: TensorProtocol where A.Element == Element>(baseTensor: A, viewIndices: [TensorIndex]) {
        guard let shapeAndCompactedView = makeShape(baseTensor.shape, view: viewIndices) else {
            fatalError("Invalid bounds for an TensorSlice")
        }
        
        self.storage = Tensor(baseTensor)
        self.shape = shapeAndCompactedView.shape
        self.compactedView = shapeAndCompactedView.compactedView
        self.viewIndices = viewIndices
        self.stride = calculateStride(shape)
        self.unified = self.shape == baseTensor.shape && !viewIndices.contains {
            if case .List(_) = $0 { // This is conservative, as the list could be 0..<count or the like.
                return false
            } else {
                return baseTensor.unified
            }
        }
    }
    
    /// Construct a TensorSlice from a complete view into `baseTensor`.
    init(baseTensor: TensorSlice<Element>) {
        self.init(baseTensor: baseTensor, viewIndices: [TensorIndex](count: baseTensor.rank, repeatedValue: TensorIndex.All))
    }
    
    /// Construct a TensorSlice from a partial view into `baseTensor` as mediated by the `viewIndices`.
    init(baseTensor: TensorSlice<Element>, viewIndices: [TensorIndex]) {
        let absoluteViewIndices = transformToAbsoluteViewIndices(baseTensor, view: viewIndices)
        self.init(baseTensor: baseTensor.storage, viewIndices: absoluteViewIndices)
    }
    
}

// MARK: - All Elements Views
extension TensorSlice {
    
    public var allElements: AnyRandomAccessCollection<Element> {
        return AnyRandomAccessCollection(AllElementsCollection(array: self))
    }
    
    public subscript(linear linearIndex: Int) -> Element {
        return self[convertIndices(linear: linearIndex, stride: stride)]
    }
    
}


// MARK: - Scalar Indexing
extension TensorSlice {
    
    private func getStorageIndices(indices: [Int]) -> [Int] {
        guard checkBounds(indices, forShape: shape) else { fatalError("TensorProtocol index out of range") }
        
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
extension TensorSlice {
    
    public subscript(indices: [TensorIndex]) -> TensorSlice<Element> {
        return TensorSlice(baseTensor: self, viewIndices: indices)
    }
    
    public subscript(indices: TensorIndex...) -> TensorSlice<Element> {
        return TensorSlice(baseTensor: self, viewIndices: indices)
    }
    
}

// MARK: - Private Helpers

// TODO: Make these less ugly.

private func makeShape(baseShape: [Int], view: [TensorIndex]) -> (shape: [Int], compactedView: [Int?])? {
    // Assumes view is within bounds.
    func calculateBound(baseCount: Int, view: TensorIndex) -> Int {
        switch view {
        case .All: return baseCount
        case .SingleValue: return 1
        case .List(let list): return list.count
        case .Range(let low, let high): return high - low
        }
    }
    
    func calculateUncompactedShape(baseShape: [Int], view: [TensorIndex]) -> [Int] {
        return zip(baseShape, view).map(calculateBound)
    }
    
    func calculateCompactedBound(baseCount: Int, view: TensorIndex) -> Int? {
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
    
    func calculateCompactedView(uncompactedShape: [Int], view: [TensorIndex]) -> [Int?] {
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

private func convertIndex(index: Int, view: TensorIndex) -> Int {
    switch view {
    case .All: return index
    case .SingleValue: fatalError("This cannot happen")
    case .List(let list): return list[index]
    case .Range(let low, _): return low + index
    }
}

private func transformToAbsoluteViewIndices<T>(baseSlice: TensorSlice<T>, view: [TensorIndex]) -> [TensorIndex] {
    guard baseSlice.shape.count == view.count else { fatalError("Incorrect number of indices to slice array") }
    guard !zip(baseSlice.shape, view).map({$1.isInbounds($0)}).contains(false) else { fatalError("Slice indices are out of bounds") }
    
    var g = view.generate()
    return zip(baseSlice.compactedView, baseSlice.viewIndices).map {
        if let d = $0.0 { return .SingleValue(d) }
        
        switch $0.1 {
        case .All:
            return g.next()! // If the parent slice is .All in a dimension, than the child's TensorIndex in that dimension is the only constraint
        case .SingleValue:
            return $0.1 // On the other hand, if the parent slice is a .SingleValue, it fully determines the relationship to the base TensorProtocol
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
