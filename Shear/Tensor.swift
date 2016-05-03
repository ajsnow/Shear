// Copyright 2016 The Shear Authors. All rights reserved.
// Use of this source code is governed by a MIT-style
// license that can be found in the LICENSE file.

import Foundation

public struct Tensor<T>: TensorProtocol {
    
    // MARK: - Associated Types
    
    public typealias Element = T
    
    // MARK: - Underlying Storage
    
    /// The functions called for a given index. One should be defined in terms of the other.
    private let cartesianFn: [Int] -> Element
    private let linearFn: Int -> Element
    // These functions perform range checking themselves.
    //
    // The reason we maintain two functions is that some Tensors will be most naturally defined one way or the other so we need both inits.
    // However, if we only supported, for example, cartesian functions natively, then linear access of, say, iota would result in linear -> cartesian -> linear index translation.
    
    // MARK: - Stored Properties
    
    public let shape: [Int]
    
    public let unified: Bool
    
    /// The stride needed to index into storage.
    private let stride: [Int]
    
    /// The total number of elements.
    private let count: Int
    
}

// MARK: - Initializers
extension Tensor {
    
    public init(shape newShape: [Int], cartesian definition: [Int] -> Element) {
        guard let newShape = checkAndReduce(newShape) else { fatalError("TensorProtocol cannot contain zero or negative length dimensions") }
        
        shape = newShape
        stride = calculateStride(shape)
        count = shape.reduce(1, combine: *)
        
        cartesianFn = definition
        linearFn = transformFn(definition, stride: stride)
        unified = false
    }
    
    public init(shape newShape: [Int], linear definition: Int -> Element) {
        guard let newShape = checkAndReduce(newShape) else { fatalError("TensorProtocol cannot contain zero or negative length dimensions") }
        
        shape = newShape
        stride = calculateStride(shape)
        count = shape.reduce(1, combine: *)
        
        cartesianFn = transformFn(definition, stride: stride)
        linearFn = definition
        unified = false
    }
    
    /// Construct a Tensor with a `shape` of elements, each initialized to `repeatedValue`.
    public init(shape newShape: [Int], repeatedValue: Element) {
        guard let newShape = checkAndReduce(newShape) else { fatalError("TensorProtocol cannot contain zero or negative length dimensions") }
        
        shape = newShape
        stride = calculateStride(shape)
        count = shape.reduce(1, combine: *)
        
        cartesianFn = { _ in repeatedValue }
        linearFn = { _ in repeatedValue }
        unified = true
    }
    
    /// Type-erase any TensorProtocol into a Tensor.
    ///
    /// The underlying TensorProtocol **must** handle range checking.
    public init<A: TensorProtocol where A.Element == Element>(_ baseTensor: A) {
        shape = baseTensor.shape
        stride = calculateStride(shape)
        count = shape.reduce(1, combine: *)
        
        cartesianFn = { indices in baseTensor[indices] }
        linearFn = { index in baseTensor[linear: index] }
        unified = baseTensor.unified
    }
    
    /// Type-erase and reshape any TensorProtocol into a Tensor.
    ///
    /// The underlying TensorProtocol **must** handle range checking.
    public init<A: TensorProtocol where A.Element == Element>(shape newShape: [Int], baseTensor: A) {
        guard let newShape = checkAndReduce(newShape) else { fatalError("TensorProtocol cannot contain zero or negative length dimensions") }
        
        shape = newShape
        stride = calculateStride(shape)
        count = shape.reduce(1, combine: *)
        
        guard count == baseTensor.shape.reduce(1, combine: *) else { fatalError("Reshaped arrays must contain the same number of elements") }
        
        let definition = { index in baseTensor[linear: index] }
        cartesianFn = transformFn(definition, stride: stride)
        linearFn = definition
        unified = baseTensor.unified
    }
    
}

// MARK: - Linear Access
extension Tensor {
    
    public var allElements: AnyRandomAccessCollection<Element> {
        return AnyRandomAccessCollection(AllElementsCollection(array: self))
    }
    
    public subscript(linear linearIndex: Int) -> Element {
        guard checkBounds(linearIndex, forCount: count) else { fatalError("TensorProtocol index out of range") }
        return linearFn(linearIndex)
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
    
    public subscript(indices: [TensorIndex]) -> TensorSlice<Element> {
        return TensorSlice(baseTensor: self, viewIndices: indices) // Bounds checking happens in TensorSlice's init.
    }
    
    public subscript(indices: TensorIndex...) -> TensorSlice<Element> {
        return TensorSlice(baseTensor: self, viewIndices: indices) // Bounds checking happens in TensorSlice's init.
    }
    
}

private func transformFn<A>(cartesianFn: [Int] -> A, stride: [Int]) -> Int -> A {
    return { index in cartesianFn(convertIndices(linear: index, stride: stride)) }
}

private func transformFn<A>(linearFn: Int -> A, stride: [Int]) -> [Int] -> A {
    return { indices in linearFn(convertIndices(cartesian: indices, stride: stride)) }
}
