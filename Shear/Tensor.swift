// Copyright 2016 The Shear Authors. All rights reserved.
// Use of this source code is governed by a MIT-style
// license that can be found in the LICENSE file.

import Foundation

public struct Tensor<Element>: TensorProtocol {
    
    // MARK: - Underlying Storage
    
    /// The functions called for a given index. One should be defined in terms of the other.
    fileprivate let cartesianFn: ([Int]) -> Element
    fileprivate let linearFn: (Int) -> Element
    // These functions perform range checking themselves.
    //
    // The reason we maintain two functions is that some Tensors will be most naturally defined one way or the other so we need both inits.
    // However, if we only supported, for example, cartesian functions natively, then linear access of, say, iota would result in linear -> cartesian -> linear index translation.
    
    // MARK: - Stored Properties
    
    public let shape: [Int]
    
    public let unified: Bool
    
    /// The stride needed to index into storage.
    fileprivate let stride: [Int]
    
    /// The total number of elements.
    fileprivate let count: Int
    
}

public extension Tensor {
    
    // MARK: - Internal Init
    
    // Internal Init handles otherwise repeatitive tasks.
    init(shape: [Int], cartesian: (([Int]) -> Element)?, linear: ((Int) -> Element)?, unified: Bool) {
        guard let shape = checkAndReduce(shape) else { fatalError("A Tensor cannot contain zero or negative length dimensions") }
        
        self.shape = shape
        self.stride = calculateStride(shape)
        self.count = shape.reduce(1, *)
        self.unified = unified
        
        switch (cartesian, linear) {
        case let (.some(cartesian), .some(linear)):
            self.cartesianFn = cartesian
            self.linearFn = linear
        case let (.some(cartesian), .none):
            self.cartesianFn = cartesian
            self.linearFn = transformFn(cartesian, stride: stride)
        case let (.none, .some(linear)):
            self.cartesianFn = transformFn(linear, stride: stride)
            self.linearFn = linear
        case (.none, .none):
            fatalError("At least one method of index translation must be defined")
        }
    }
    
    // MARK: - Conformance Init
    
    /// Construct a Tensor with a `shape` of elements, each initialized to `repeatedValue`.
    public init(shape: [Int], repeatedValue: Element) {
        self.init(shape: shape, cartesian: { _ in repeatedValue }, linear: { _ in repeatedValue }, unified: true)
    }
    
    /// Convert the native Array of `values` into a Tensor of `shape`.
    public init(shape: [Int], values: [Element]) {
        self.init(shape: shape, cartesian: nil, linear: { i in values[i] }, unified: true)
    }
    
    /// Construct a Tensor with the elements of `tensor` of `shape`.
    public init(shape: [Int], tensor: Tensor<Element>) {
        guard shape.reduce(1, *) == tensor.count else { fatalError("Reshaped Tensors must contain the same number of elements") }
        // It's a little redundant to compute the shape twice, but that's not a high cost.
        
        self.init(shape: shape, cartesian: nil, linear: tensor.linearFn, unified: tensor.unified) // The cartesian function changes unless the shape == tensor.shape, so we recompute it from the linear function that does not change.
    }
    
    /// Construct a Tensor a slice with `view` into `tensor`.
    init(view: [TensorIndex], tensor: Tensor<Element>) {
        guard let (shape, compactView) = makeSliceIndexingShapeAndView(tensor.shape, view: view) else {
            fatalError("Invalid bounds for an TensorSlice")
        }
        
        let cartesian = { (indices: [Int]) -> Element in
            var g = indices.makeIterator()
            let underlyingIndices = zip(compactView, view).map { (c, v) -> Int in
                if let d = c { return d }
                return convertIndex(g.next()!, view: v)
            }
            return tensor.cartesianFn(underlyingIndices)
        }
        
        self.init(shape: shape, cartesian: cartesian, linear: nil, unified: false)
    }
    
    /// Type-convert any TensorProtocol adopter into a Tensor.
    public init<A: TensorProtocol>(_ tensor: A) where A.Element == Element {
        // Likely doubles up on bounds checking.
        self.init(shape: tensor.shape, cartesian: { indices in tensor[indices] }, linear: { index in tensor[linear: index] }, unified: tensor.unified)
    }
    
    /// Constructs a Tensor with the given `shape` where the values are a function of their `cartesian` indices.
    public init(shape: [Int], cartesian: @escaping ([Int]) -> Element) {
        self.init(shape: shape, cartesian: cartesian, linear: nil, unified: false) // We have to be conservative with unified's condition here since we could get closures dragging lots of Tensors in with them.
    }
    
    /// Constructs a Tensor with the given `shape` where the values are a function of their `linear` index.
    public init(shape: [Int], linear: @escaping (Int) -> Element) {
       self.init(shape: shape, cartesian: nil, linear: linear, unified: false) // We have to be conservative with unified's condition here since we could get closures dragging lots of Tensors in with them.
    }
    
}

// MARK: - Linear Indexing
extension Tensor {
    
    public var allElements: AnyRandomAccessCollection<Element> {
        return AnyRandomAccessCollection(AllElementsCollection(array: self))
    }
    
    public subscript(linear linearIndex: Int) -> Element {
        guard checkBounds(linearIndex, forCount: count) else { fatalError("TensorProtocol index out of range") }
        return linearFn(linearIndex)
    }
    
}

// MARK: - Linear Slicing

extension Tensor {
    
    public subscript(linear indices: Range<Int>) -> Tensor<Element> {
        guard checkBounds(indices.lowerBound, forCount: count) &&
            checkBounds(indices.upperBound, forCount: count) else { fatalError("TensorProtocol index out of range") }
        return Tensor(shape: [indices.count], linear: { self[linear: $0] })
    }
}

// MARK: - Scalar Indexing
extension Tensor {
    
    public subscript(indices: [Int]) -> Element {
        guard checkBounds(indices, forShape: shape) else { fatalError("TensorProtocol index out of range") }
        return cartesianFn(indices)
    }
    
    public subscript(indices: Int...) -> Element {
        guard checkBounds(indices, forShape: shape) else { fatalError("TensorProtocol index out of range") }
        return cartesianFn(indices)
    }
    
}

// MARK: - Slice Indexing
extension Tensor {
    
    public subscript(indices: [TensorIndex]) -> Tensor<Element> {
        return Tensor(view: indices, tensor: self)
        
    }
    
    public subscript(indices: TensorIndex...) -> Tensor<Element> {
        return Tensor(view: indices, tensor: self)
    }
    
}

private func transformFn<A>(_ cartesianFn: @escaping ([Int]) -> A, stride: [Int]) -> (Int) -> A {
    return { index in cartesianFn(convertIndices(linear: index, stride: stride)) }
}

private func transformFn<A>(_ linearFn: @escaping (Int) -> A, stride: [Int]) -> ([Int]) -> A {
    return { indices in linearFn(convertIndices(cartesian: indices, stride: stride)) }
}

private func makeSliceIndexingShapeAndView(_ baseShape: [Int], view: [TensorIndex]) -> (shape: [Int], compactedView: [Int?])? {
    // Assumes view is within bounds.
    func calculateBound(_ baseCount: Int, view: TensorIndex) -> Int {
        switch view {
        case .all: return baseCount
        case .singleValue: return 1
        case .list(let list): return list.count
        case .range(let low, let high): return high - low
        }
    }
    
    func calculateUncompactedShape(_ baseShape: [Int], view: [TensorIndex]) -> [Int] {
        return zip(baseShape, view).map(calculateBound)
    }
    
    func calculateCompactedBound(_ baseCount: Int, view: TensorIndex) -> Int? {
        guard baseCount == 1 else { return nil }
        switch view {
        case .all:
            return 0 // Cannot be reached, as there cannot be singular dimensions in the base array's shape either.
        case .singleValue(let sv):
            return sv
        case .list(let list):
            return list.first! // If the list is empty we have a problem we should have detected earlier.
        case .range(let low, _):
            return low
        }
    }
    
    func calculateCompactedView(_ uncompactedShape: [Int], view: [TensorIndex]) -> [Int?] {
        return zip(uncompactedShape, view).map(calculateCompactedBound)
    }
    
    // Check for correct number of indices
    guard baseShape.count == view.count else { return nil }
    guard !zip(baseShape, view).map({$1.isInbounds($0)}).contains(false) else { return nil }
    
    let uncompactedShape = calculateUncompactedShape(baseShape, view: view)
    guard !uncompactedShape.contains(where: {$0 < 1}) else { return nil }
    
    let compactedView = calculateCompactedView(uncompactedShape, view: view)
    return (uncompactedShape.filter {$0 != 1}, compactedView)
}

private func convertIndex(_ index: Int, view: TensorIndex) -> Int {
    switch view {
    case .all: return index
    case .singleValue: fatalError("This cannot happen")
    case .list(let list): return list[index]
    case .range(let low, _): return low + index
    }
}

