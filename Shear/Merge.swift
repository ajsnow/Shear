// Copyright 2016 The Shear Authors. All rights reserved.
// Use of this source code is governed by a MIT-style
// license that can be found in the LICENSE file.

import Foundation

public extension Array {
    
    /// Returns a DenseArray with the contents of additionalItems appended to the last axis of the Array.
    ///
    /// e.g.
    ///    1 2 | 5 6 --> 1 2 5 6
    ///    3 4 | 7 8 --> 3 4 7 8
    public func append<A: Array where A.Element == Element>(additionalItems: A) -> ComputedArray<Element> {
        return zipVectorMap(self, additionalItems, byRows: true, transform: { $0 + $1 } )
        //        guard rank == additionalItems.rank && shape.dropLast().elementsEqual(additionalItems.shape.dropLast()) ||
        //            rank == additionalItems.rank + 1 && shape.dropLast().elementsEqual(additionalItems.shape) else {
        //               fatalError("Shape of additionalItems must match the base array in all but the last dimension")
        //        }
        //
        //        var newShape = shape
        //        newShape[newShape.count - 1] += rank == additionalItems.rank ? additionalItems.shape.last! : 1
        //        return ComputedArray(shape: newShape, cartesian: { indices in
        //            if indices.last! < self.shape.last! {
        //                return self[indices]
        //            }
        //            var viewIndices = [Int](indices.dropLast()) + [indices.last! - self.shape.last!] as [Int]
        //            if self.rank != additionalItems.rank {
        //                viewIndices = [Int](viewIndices.dropLast())
        //            }
        //            return additionalItems[viewIndices]
        //        })
    }
    
    /// Returns a DenseArray with the contents of additionalItems concatenated to the first axis of the Array.
    ///
    /// e.g.
    ///    1 2 | 5 6 --> 1 2
    ///    3 4 | 7 8 --> 3 4
    ///                  5 6
    ///                  7 8
    public func concat<A: Array where A.Element == Element>(additionalItems: A) -> ComputedArray<Element> {
        return zipVectorMap(self, additionalItems, byRows: false, transform: {$0 + $1})
    }
    
    /// Returns a DenseArray with a rank - 1 array of additionalitem appended to the last axis of the Array.
    public func append(additionalItem: Element) -> ComputedArray<Element> {
        return vectorMap(byRows: true, transform: {$0 + [additionalItem]})
    }
    
    /// Returns a DenseArray with a rank - 1 array of additionalitem concatenated to the first axis of the Array.
    public func concat(additionalItem: Element) -> ComputedArray<Element> {
        return vectorMap(byRows: false, transform: {$0 + [additionalItem]})
        // This could be optimized to the following:
        //     return DenseArray(shape: [shape[0] + 1] + shape.dropFirst(), baseArray: [Element](allElements) + [Element](count: shape.dropFirst().reduce(*), repeatedValue: additionalItem))
        // But given all preformance we're leaving on the table elsewhere, it seems silly to break the nice symmetry for an unimportant function.
        // I've also not benchmarked the difference, so this could turn out to be a pessimization, though that would shock me.
    }
    
    /// Returns a DenseArray of a higher order by creating a new first axis. Both input arrays must be the same shape.
    /// e.g.
    ///    1 2 3 4 | 5 6 7 8 --> 1 2 3 4
    ///                          5 6 7 8
    public func laminate<A: Array where A.Element == Element>(additionalItems: A) -> ComputedArray<Element> {
        guard shape == additionalItems.shape else {
            fatalError("Arrays must have same shape to be laminated")
        }
        let left = ComputedArray(self)
        let right = ComputedArray(additionalItems) // type erase both so we can put them in an array.
        return ([left, right] as [ComputedArray<Element>]).ravel().disclose()
    }
    
    /// Returns a DenseArray of a higher order by creating a new last axis. Both input arrays must be the same shape.
    /// e.g.
    ///    1 2 3 4 | 5 6 7 8 --> 1 5
    ///                          2 6
    ///                          3 7
    ///                          4 8
    public func interpose<A: Array where A.Element == Element>(additionalItems: A) -> ComputedArray<Element> {
        guard shape == additionalItems.shape else {
            fatalError("Arrays must have same shape to be interposed")
        }
        let left = ComputedArray(self)
        let right = ComputedArray(additionalItems) // type erase both so we can put them in an array.
        return ([left, right] as [ComputedArray<Element>]).ravel().discloseFirst()
    }
    
}
