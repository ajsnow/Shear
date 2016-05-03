// Copyright 2016 The Shear Authors. All rights reserved.
// Use of this source code is governed by a MIT-style
// license that can be found in the LICENSE file.

import Foundation

public struct DenseTensor<T>: TensorProtocol, MutableTensorProtocol {
    
    // MARK: - Associated Types
    
    public typealias Element = T
    
    // MARK: - Underlying Storage
    
    /// The flat builtin array that serves as the underlying backing storage for this `$TypeName`.
    private var storage: [T]
    
    // MARK: - Stored Properties
    
    public let shape: [Int]
    
    public let unified = true
    
    /// The stride needed to index into storage.
    private let stride: [Int]
    
}

// MARK: - Initializers
extension DenseTensor {
    
    /// Reshape a one-dimensional, built-in `baseTensor` into a DenseTensor of `shape`.
    public init(shape newShape: [Int], baseTensor: [Element]) {
        guard let newShape = checkAndReduce(newShape) else { fatalError("TensorProtocol cannot contain zero or negative length dimensions") }
        
        shape = newShape
        stride = calculateStride(shape)
        
        let count = shape.isEmpty ? 1 : shape.reduce(*)
        guard count == baseTensor.count else { fatalError("Tensor's element's count does not match the product of it's dimensions.") }
        
        storage = baseTensor
    }
    
    /// Construct a DenseTensor with a `shape` of elements, each initialized to `repeatedValue`.
    public init(shape newShape: [Int], repeatedValue: Element) {
        let storage = [Element](count: newShape.isEmpty ? 1 : newShape.reduce(*), repeatedValue: repeatedValue)
        self.init(shape: newShape, baseTensor: storage)
    }
    
    /// Reshape any TensorProtocol `baseTensor` into a new DenseTensor of `shape`.
    public init<A: TensorProtocol where A.Element == Element>(shape newShape: [Int], baseTensor: A) {
        self.init(shape: newShape, baseTensor: baseTensor.allElements.map {$0})
    }
    
    /// Convert any TensorProtocol `baseTensor` into a new DenseTensor of the same `shape`.
    public init<A: TensorProtocol where A.Element == Element>(_ baseTensor: A) {
        self.init(shape: baseTensor.shape, baseTensor: baseTensor.allElements.map {$0})
    }
    
    /// Reshape a DenseTensor `baseTensor` into a new DenseTensor of `shape`.
    public init(shape newShape: [Int], baseTensor: DenseTensor<Element>) {
        self.init(shape: newShape, baseTensor: baseTensor.storage)
    }
    
    /// Construct a DenseTensor from a `collection` of Tensors.
    ///
    /// The count of the `collection` is the length of the resulting Tensor's first axis.
    public init<C: CollectionType, A: TensorProtocol where
        A.Element == Element,
        C.Generator.Element == A,
        C.Index.Distance == Int>
        (collection: C) {
        if collection.isEmpty {
            fatalError("Cannot construct an TensorProtocol from empty collection: can't infer shape")
        }
        
        let subShape = collection.first!.shape
        guard !collection.contains({$0.shape != subShape}) else {
            fatalError("Tensors in the collection constructor must have the same shape")
        }
        
        let shape = [collection.count] as [Int] + subShape
        let storage = collection.reduce([Element](), combine: {$0 + $1.allElements})
        self.init(shape: shape, baseTensor: storage)
    }
    
    /// Construct a DenseTensor from a `collection` of Tensors.
    ///
    /// The count of the `collection` is the length of the resulting Tensor's last axis.
    public init<C: CollectionType, A: TensorProtocol where
        A.Element == Element,
        C.Generator.Element == A,
        C.Index.Distance == Int>
        (collectionOnLastAxis collection: C) {
        if collection.isEmpty {
            fatalError("Cannot construct an TensorProtocol from empty collection: can't infer shape")
        }
        
        let subShape = collection.first!.shape
        guard !collection.contains({ $0.shape != subShape }) else {
            fatalError("Tensors in the collection constructor must have the same shape")
        }
        
        
        let shape = subShape + [collection.count] as [Int]
        var storage = [Element]()
        for i in 0..<Int(collection.first!.allElements.count) {
            for array in collection {
                storage.append(array[linear: i])
            }
        }
        self.init(shape: shape, baseTensor: storage)
    }
    
}

// MARK: - Linear Access
extension DenseTensor {
    
    public var allElements: AnyRandomAccessCollection<Element> {
        return AnyRandomAccessCollection(storage)
    }
    
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
extension DenseTensor {
    
    func getStorageIndex(indices: [Int]) -> Int {
        guard checkBounds(indices, forShape: shape) else { fatalError("TensorProtocol index out of range") }
        return convertIndices(cartesian: indices, stride: stride)
    }
    
    public subscript(indices: [Int]) -> Element {
        get {
            return self[linear: getStorageIndex(indices)]
        }
        set(newValue) {
            self[linear: getStorageIndex(indices)] = newValue
        }
    }
    
    public subscript(indices: Int...) -> Element {
        get {
            return self[linear: getStorageIndex(indices)]
        }
        set(newValue) {
            self[linear: getStorageIndex(indices)] = newValue
        }
    }
    
}

// MARK: - Slice Indexing
extension DenseTensor {
    
    public subscript(indices: [TensorIndex]) -> TensorSlice<Element> {
        return TensorSlice(baseTensor: self, viewIndices: indices)
    }
    
    public subscript(indices: TensorIndex...) -> TensorSlice<Element> {
        return TensorSlice(baseTensor: self, viewIndices: indices)
    }
    
}
