// Copyright 2016 The Shear Authors. All rights reserved.
// Use of this source code is governed by a MIT-style
// license that can be found in the LICENSE file.

import Foundation

public extension Array {
    
    /// Returns a new ComputedArray with the contents of `self` with `shape`.
    public func reshape(shape: [Int]) -> ComputedArray<Element> {
        return ComputedArray(shape: shape, baseArray: self)
    }
    
    /// Returns a new ComputedArray with the contents of `self` as a vector.
    public func ravel() -> ComputedArray<Element> {
        return ComputedArray(shape: [Int(allElements.count)], baseArray: self)
    }
    
    /// Reverse the order of Elements along the last axis (columns).
    public func reverse() -> ComputedArray<Element> {
        return self.vectorMap(byRows: true, transform: { $0.reverse() } )
    }
    
    /// Reverse the order of Elements along the first axis.
    public func flip() -> ComputedArray<Element> {
        return self.vectorMap(byRows: false, transform: { $0.reverse() } )
    }
    
    /// Returns a ComputedArray whose dimensions are reversed.
    public func transpose() -> ComputedArray<Element> {
        return ComputedArray(shape: shape.reverse(), cartesian: {indices in
            self[indices.reverse()]
        })
    }
    
    /// Returns a DenseArray whose columns are shifted `count` times.
    public func rotate(count: Int) -> ComputedArray<Element> {
        return vectorMap(byRows: true, transform: {$0.rotate(count)})
    }
    
    /// Returns a DenseArray whose first dimension's elements are shifted `count` times.
    public func rotateFirst(count: Int) -> ComputedArray<Element> {
        return vectorMap(byRows: false, transform: {$0.rotate(count)})
    }
    
}
