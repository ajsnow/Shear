// Copyright 2016 The Shear Authors. All rights reserved.
// Use of this source code is governed by a MIT-style
// license that can be found in the LICENSE file.

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
    
    /// Reshape a one-dimensional, built-in `baseArray` into a DenseArray of `shape`.
    public init(shape newShape: [Int], baseArray: [Element]) {
        guard !newShape.contains({ $0 < 1 }) else { fatalError("Array cannot contain zero or negative length dimensions.") }
        
        shape = newShape.filter { $0 > 1 } // shape is defined in terms of non-unary dimensions.
        stride = calculateStride(shape)
        
        let count = shape.isEmpty ? 1 : shape.reduce(*)
        guard count == baseArray.count else { fatalError("Array's element's count does not match the product of it's dimensions.") }
        
        storage = baseArray
    }
    
    /// Construct a DenseArray with a `shape` of elements, each initialized to `repeatedValue`.
    public init(shape newShape: [Int], repeatedValue: Element) {
        let storage = [Element](count: newShape.isEmpty ? 1 : newShape.reduce(*), repeatedValue: repeatedValue)
        self.init(shape: newShape, baseArray: storage)
    }
    
    /// Reshape any Array `baseArray` into a new DenseArray of `shape`.
    public init<A: Array where A.Element == Element>(shape newShape: [Int], baseArray: A) {
        self.init(shape: newShape, baseArray: baseArray.allElements.map {$0})
    }
    
    /// Reshape a DenseArray `baseArray` into a new DenseArray of `shape`.
    public init(shape newShape: [Int], baseArray: DenseArray<Element>) {
        self.init(shape: newShape, baseArray: baseArray.storage)
    }
    
    /// Construct a DenseArray from a `collection` of Arrays.
    /// The count of the `collection` is the length of the resulting Array's first axis.
    public init<C: CollectionType, A: Array where
        A.Element == Element,
        C.Generator.Element == A,
        C.Index.Distance == Int>
        (collection: C) {
            if collection.isEmpty {
                fatalError("Cannot construct an Array from empty collection: can't infer shape")
            }
            
            
            let subShape = collection.first!.shape
            guard !collection.contains({$0.shape != subShape}) else {
                fatalError("Arrays in the collection constructor must have the same shape")
            }
            
            let shape = [collection.count] as [Int] + subShape
            let storage = collection.reduce([Element](), combine: {$0 + $1.allElements})
            self.init(shape: shape, baseArray: storage)
    }
    
    /// Construct a DenseArray from a `collection` of Arrays.
    /// The count of the `collection` is the length of the resulting Array's last axis.
    public init<C: CollectionType, A: Array where
        A.Element == Element,
        C.Generator.Element == A,
        C.Index.Distance == Int>
        (collectionOnLastAxis collection: C) {
            if collection.isEmpty {
                fatalError("Cannot construct an Array from empty collection: can't infer shape")
            }
            
            let subShape = collection.first!.shape
            guard !collection.contains({ $0.shape != subShape }) else {
                fatalError("Arrays in the collection constructor must have the same shape")
            }
            
            
            let shape = subShape + [collection.count] as [Int]
            var storage = [Element]()
            for i in 0..<Int(collection.first!.allElements.count) {
                for array in collection {
                    storage.append(array[linear: i])
                }
            }
            self.init(shape: shape, baseArray: storage)
    }
    
}

// MARK: - Linear Access
extension DenseArray {
    
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
