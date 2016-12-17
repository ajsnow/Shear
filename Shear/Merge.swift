// Copyright 2016 The Shear Authors. All rights reserved.
// Use of this source code is governed by a MIT-style
// license that can be found in the LICENSE file.

import Foundation

public extension TensorProtocol {
    
    /// Returns a DenseTensor with the contents of additionalItems appended to the last axis of the TensorProtocol.
    ///
    /// e.g.
    ///    1 2 | 5 6 --> 1 2 5 6
    ///    3 4 | 7 8 --> 3 4 7 8
    public func append<A: TensorProtocol>(_ additionalItems: A) -> Tensor<Element> where A.Element == Element {
        return zipVectorMap(self, additionalItems, byRows: true, transform: { $0 + $1 } )
        //        guard rank == additionalItems.rank && shape.dropLast().elementsEqual(additionalItems.shape.dropLast()) ||
        //            rank == additionalItems.rank + 1 && shape.dropLast().elementsEqual(additionalItems.shape) else {
        //               fatalError("Shape of additionalItems must match the base array in all but the last dimension")
        //        }
        //
        //        var newShape = shape
        //        newShape[newShape.count - 1] += rank == additionalItems.rank ? additionalItems.shape.last! : 1
        //        return Tensor(shape: newShape, cartesian: { indices in
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
    
    /// Returns a DenseTensor with the contents of additionalItems concatenated to the first axis of the TensorProtocol.
    ///
    /// e.g.
    ///    1 2 | 5 6 --> 1 2
    ///    3 4 | 7 8 --> 3 4
    ///                  5 6
    ///                  7 8
    public func concat<A: TensorProtocol>(_ additionalItems: A) -> Tensor<Element> where A.Element == Element {
        return zipVectorMap(self, additionalItems, byRows: false, transform: {$0 + $1})
    }
    
    /// Returns a DenseTensor with a rank - 1 array of additionalitem appended to the last axis of the TensorProtocol.
    public func append(_ additionalItem: Element) -> Tensor<Element> {
        return vectorMap(byRows: true, transform: {$0 + [additionalItem]})
    }
    
    /// Returns a DenseTensor with a rank - 1 array of additionalitem concatenated to the first axis of the TensorProtocol.
    public func concat(_ additionalItem: Element) -> Tensor<Element> {
        return vectorMap(byRows: false, transform: {$0 + [additionalItem]})
        // This could be optimized to the following:
        //     return DenseTensor(shape: [shape[0] + 1] + shape.dropFirst(), baseTensor: [Element](allElements) + [Element](count: shape.dropFirst().reduce(*), repeatedValue: additionalItem))
        // But given all preformance we're leaving on the table elsewhere, it seems silly to break the nice symmetry for an unimportant function.
        // I've also not benchmarked the difference, so this could turn out to be a pessimization, though that would shock me.
    }
    
    /// Returns a DenseTensor of a higher order by creating a new first axis. Both input arrays must be the same shape.
    /// e.g.
    ///    1 2 3 4 | 5 6 7 8 --> 1 2 3 4
    ///                          5 6 7 8
    public func laminate<A: TensorProtocol>(_ additionalItems: A) -> Tensor<Element> where A.Element == Element {
        guard shape == additionalItems.shape else {
            fatalError("Tensors must have same shape to be laminated")
        }
        let left = Tensor(self)
        let right = Tensor(additionalItems) // type erase both so we can put them in an array.
        return ([left, right] as [Tensor<Element>]).ravel().disclose()
    }
    
    /// Returns a DenseTensor of a higher order by creating a new last axis. Both input arrays must be the same shape.
    /// e.g.
    ///    1 2 3 4 | 5 6 7 8 --> 1 5
    ///                          2 6
    ///                          3 7
    ///                          4 8
    public func interpose<A: TensorProtocol>(_ additionalItems: A) -> Tensor<Element> where A.Element == Element {
        guard shape == additionalItems.shape else {
            fatalError("Tensors must have same shape to be interposed")
        }
        let left = Tensor(self)
        let right = Tensor(additionalItems) // type erase both so we can put them in an array.
        return ([left, right] as [Tensor<Element>]).ravel().discloseFirst()
    }
    
}
