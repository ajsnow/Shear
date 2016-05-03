// Copyright 2016 The Shear Authors. All rights reserved.
// Use of this source code is governed by a MIT-style
// license that can be found in the LICENSE file.

import Foundation

public extension TensorProtocol {
    
    /// Returns a new Tensor with the contents of `self` with `shape`.
    func reshape(shape: [Int]) -> Tensor<Element> {
        return Tensor(shape: shape, baseTensor: self)
    }
    
    /// Returns a new Tensor with the contents of `self` as a vector.
    func ravel() -> Tensor<Element> {
        return Tensor(shape: [Int(allElements.count)], baseTensor: self)
    }
    
    /// Reverse the order of Elements along the last axis (columns).
    func reverse() -> Tensor<Element> {
        return self.vectorMap(byRows: true, transform: { $0.reverse() } )
    }
    
    /// Reverse the order of Elements along the first axis.
    func flip() -> Tensor<Element> {
        return self.vectorMap(byRows: false, transform: { $0.reverse() } )
    }
    
    /// Returns a Tensor whose dimensions are reversed.
    func transpose() -> Tensor<Element> {
        return Tensor(shape: shape.reverse(), cartesian: {indices in
            self[indices.reverse()]
        })
    }

    /// Returns a Tensor whose dimensions map to self's dimensions specified each member of `axes`.
    /// The axes array must have the same count as self's rank, and must contain all 0...axes.maxElement()
    func transpose(axes: [Int]) -> Tensor<Element> {
        guard axes.maxElement() < rank else { fatalError("Yo") }
        guard axes.count == rank else { fatalError("Yo") }

        var alreadySeen: Set<Int> = []
        let newShape = axes.flatMap { axis -> Int? in
            if alreadySeen.contains(axis) { return nil }
            alreadySeen.insert(axis)
            return shape[axis]
        }
        
        guard alreadySeen.elementsEqual(0...axes.maxElement()!) else { fatalError("Yo") }
        
        return Tensor(shape: newShape, cartesian: { indices in
            let originalIndices = axes.map { indices[$0] }
            return self[originalIndices]
        })
    }
    
    /// Returns a DenseTensor whose columns are shifted `count` times.
    func rotate(count: Int) -> Tensor<Element> {
        return vectorMap(byRows: true, transform: {$0.rotate(count)})
    }
    
    /// Returns a DenseTensor whose first dimension's elements are shifted `count` times.
    func rotateFirst(count: Int) -> Tensor<Element> {
        return vectorMap(byRows: false, transform: {$0.rotate(count)})
    }
    
}
