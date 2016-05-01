// Copyright 2016 The Shear Authors. All rights reserved.
// Use of this source code is governed by a MIT-style
// license that can be found in the LICENSE file.

import Foundation

public struct ComputedArray<T>: Array {
    
    // MARK: - Associated Types
    
    public typealias Element = T
    
    // MARK: - Underlying Storage
    
    /// The functions called for a given index. One should be defined in terms of the other.
    private let cartesianFn: [Int] -> Element
    private let linearFn: Int -> Element
    // These functions perform range checking themselves.
    //
    // The reason we maintain two functions is that some ComputedArrays will be most naturally defined one way or the other so we need both inits.
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
extension ComputedArray {
    
    public init(shape newShape: [Int], cartesian definition: [Int] -> Element) {
        guard !newShape.contains({ $0 < 1 }) else { fatalError("Array cannot contain zero or negative length dimensions") }
        
        shape = newShape.filter { $0 > 1 } // shape is defined in terms of non-unary dimensions.
        stride = calculateStride(shape)
        count = shape.reduce(1, combine: *)
        
        cartesianFn = checkFn(definition, shape: shape)
        linearFn = checkFn(transformFn(definition, stride: stride), count: count)
        unified = false
    }
    
    public init(shape newShape: [Int], linear definition: Int -> Element) {
        guard !newShape.contains({ $0 < 1 }) else { fatalError("Array cannot contain zero or negative length dimensions") }
        
        shape = newShape.filter { $0 > 1 } // shape is defined in terms of non-unary dimensions.
        stride = calculateStride(shape)
        count = shape.reduce(1, combine: *)
        
        cartesianFn = checkFn(transformFn(definition, stride: stride), shape: shape)
        linearFn = checkFn(definition, count: count)
        unified = false
    }
    
    /// Construct a ComputedArray with a `shape` of elements, each initialized to `repeatedValue`.
    public init(shape newShape: [Int], repeatedValue: Element) {
        guard !newShape.contains({ $0 < 1 }) else { fatalError("Array cannot contain zero or negative length dimensions") }
        
        shape = newShape.filter { $0 > 1 } // shape is defined in terms of non-unary dimensions.
        stride = calculateStride(shape)
        count = shape.reduce(1, combine: *)
        
        cartesianFn = checkFn({ _ in repeatedValue }, shape: shape)
        linearFn = checkFn({ _ in repeatedValue }, count: count)
        unified = true
    }
    
    /// Type-erase any Array into a ComputedArray.
    ///
    /// The underlying Array **must** handle range checking.
    public init<A: Array where A.Element == Element>(_ baseArray: A) {
        shape = baseArray.shape
        stride = calculateStride(shape)
        count = shape.reduce(1, combine: *)
        
        cartesianFn = { indices in baseArray[indices] }
        linearFn = { index in baseArray[linear: index] }
        unified = baseArray.unified
    }
    
    /// Type-erase and reshape any Array into a ComputedArray.
    ///
    /// The underlying Array **must** handle range checking.
    public init<A: Array where A.Element == Element>(shape newShape: [Int], baseArray: A) {
        guard !newShape.contains({ $0 < 1 }) else { fatalError("Array cannot contain zero or negative length dimensions") }
        
        shape = newShape.filter { $0 > 1 } // shape is defined in terms of non-unary dimensions.
        stride = calculateStride(shape)
        count = shape.reduce(1, combine: *)
        
        guard count == baseArray.shape.reduce(1, combine: *) else { fatalError("Reshaped arrays must contain the same number of elements") }
        
        let definition = { index in baseArray[linear: index] }
        cartesianFn = checkFn(transformFn(definition, stride: stride), shape: shape)
        linearFn = definition
        unified = baseArray.unified
    }
}

// MARK: - Linear Access
extension ComputedArray {
    
    public var allElements: AnyRandomAccessCollection<Element> {
        return AnyRandomAccessCollection(AllElementsCollection(array: self))
    }
    
    public subscript(linear linearIndex: Int) -> Element {
        guard checkBounds(linearIndex, forCount: count) else { fatalError("Array index out of range") }
        return linearFn(linearIndex)
    }
    
}

// MARK: - Scalar Indexing
extension ComputedArray {
    
    public subscript(indices: [Int]) -> Element {
        guard checkBounds(indices, forShape: shape) else { fatalError("Array index out of range") }
        return cartesianFn(indices)
    }
    
    public subscript(indices: Int...) -> Element {
        guard checkBounds(indices, forShape: shape) else { fatalError("Array index out of range") }
        return cartesianFn(indices)
    }
    
}

// MARK: - Slice Indexing
extension ComputedArray {
    
    public subscript(indices: [ArrayIndex]) -> ArraySlice<Element> {
        return ArraySlice(baseArray: self, viewIndices: indices)
    }
    
    public subscript(indices: ArrayIndex...) -> ArraySlice<Element> {
        return ArraySlice(baseArray: self, viewIndices: indices)
    }
    
}

private func checkFn<A>(cartesianFn: [Int] -> A, shape: [Int]) -> [Int] -> A {
    return { indices in
        guard checkBounds(indices, forShape: shape) else { fatalError("Array index out of range") }
        return cartesianFn(indices)
    }
}

private func checkFn<A>(linearFn: Int -> A, count: Int) -> Int -> A {
    return { index in
        guard checkBounds(index, forCount: count) else { fatalError("Array index out of range") }
        return linearFn(index)
    }
}

private func transformFn<A>(cartesianFn: [Int] -> A, stride: [Int]) -> Int -> A {
    return { index in cartesianFn(convertIndices(linear: index, stride: stride)) }
}

private func transformFn<A>(linearFn: Int -> A, stride: [Int]) -> [Int] -> A {
    return { indices in linearFn(convertIndices(cartesian: indices, stride: stride)) }
}
