// Copyright 2016 The Shear Authors. All rights reserved.
// Use of this source code is governed by a MIT-style
// license that can be found in the LICENSE file.

import Foundation

// MARK: - Enclose
public extension TensorProtocol {
    
    // TODO: Supporting the full APL-style axes enclose requires support for general dimensional reodering.
    /// Encloses the TensorProtocol upon the `axes` specified, resulting in an TensorProtocol of Tensors.
    /// If no `axes` are provided, encloses over the whole TensorProtocol.
    /// Enclose is equivilant to APL's enclose when the axes are in accending order.
    /// i.e.
    ///     A.enclose(2, 0, 5) == ⊂[0 2 5]A
    ///     A.enclose(2, 0, 5) != ⊂[2 0 5]A
    func enclose(axes: Int...) -> Tensor<Tensor<Element>> {
        return enclose(axes)
    }
    
    // TODO: Supporting the full APL-style axes enclose requires support for general dimensional reodering.
    /// Encloses the TensorProtocol upon the `axes` specified, resulting in an TensorProtocol of Tensors.
    /// If no `axes` are provided, encloses over the whole TensorProtocol.
    /// Enclose is equivilant to APL's enclose when the axes are in accending order.
    /// i.e.
    ///     A.enclose([2, 0, 5]) == ⊂[0 2 5]A
    ///     A.enclose([2, 0, 5]) != ⊂[2 0 5]A
    func enclose(axes: [Int]) -> Tensor<Tensor<Element>> {
        guard !axes.isEmpty else { return ([Tensor(self)] as [Tensor<Element>]).ravel() }
        
        let axes = Set(axes).sort() // Filter out any repeated axes.
        guard !axes.contains({ !checkBounds($0, forCount: rank) }) else { fatalError("All axes must be between 0..<rank") }
        
        let newShape = [Int](shape.enumerate().lazy.filter { !axes.contains($0.index) }.map { $0.element })
        
        let internalIndicesList = makeRowMajorIndexGenerator(newShape).map { newIndices -> [TensorIndex] in
            var internalIndices = newIndices.map { TensorIndex.SingleValue($0) }
            for a in axes {
                internalIndices.insert(.All, atIndex: a) // N.B. This only works when the axes are sorted.
            }
            return internalIndices
        }
        
        return Tensor(shape: newShape, linear: { Tensor(self[internalIndicesList[$0]]) })
    }
    
}

// MARK: - Disclose
public extension TensorProtocol where Element: TensorProtocol {
    
    func discloseEager() -> Tensor<Element.Element> {
        let newShape = shape + self.allElements.first!.shape
        let baseTensor = self.allElements.flatMap { $0.allElements }
        return Tensor(DenseTensor(shape: newShape, baseTensor: baseTensor))
    }
    
    func disclose() -> Tensor<Element.Element> {
        let newShape = shape + self.allElements.first!.shape
        return Tensor(shape: newShape, cartesian: { indices in
            let subTensor = self[[Int](indices[0..<self.rank])]
            return subTensor[[Int](indices[self.rank..<indices.count])]
        })
    }
    
    func discloseFirst() -> Tensor<Element.Element> {
        let newShape = self.allElements.first!.shape + shape
        return Tensor(shape: newShape, cartesian: { indices in
            let subTensor = self[[Int](indices[indices.count - self.rank..<indices.count])]
            return subTensor[[Int](indices[0..<indices.count - self.rank])]
        })
    }
    
}