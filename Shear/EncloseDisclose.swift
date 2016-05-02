// Copyright 2016 The Shear Authors. All rights reserved.
// Use of this source code is governed by a MIT-style
// license that can be found in the LICENSE file.

import Foundation

// MARK: - Enclose
public extension Array {
    
    // TODO: Supporting the full APL-style axes enclose requires support for general dimensional reodering.
    /// Encloses the Array upon the `axes` specified, resulting in an Array of Arrays.
    /// If no `axes` are provided, encloses over the whole Array.
    /// Enclose is equivilant to APL's enclose when the axes are in accending order.
    /// i.e.
    ///     A.enclose(2, 0, 5) == ⊂[0 2 5]A
    ///     A.enclose(2, 0, 5) != ⊂[2 0 5]A
    func enclose(axes: Int...) -> ComputedArray<ComputedArray<Element>> {
        return enclose(axes)
    }
    
    // TODO: Supporting the full APL-style axes enclose requires support for general dimensional reodering.
    /// Encloses the Array upon the `axes` specified, resulting in an Array of Arrays.
    /// If no `axes` are provided, encloses over the whole Array.
    /// Enclose is equivilant to APL's enclose when the axes are in accending order.
    /// i.e.
    ///     A.enclose([2, 0, 5]) == ⊂[0 2 5]A
    ///     A.enclose([2, 0, 5]) != ⊂[2 0 5]A
    func enclose(axes: [Int]) -> ComputedArray<ComputedArray<Element>> {
        guard !axes.isEmpty else { return ([ComputedArray(self)] as [ComputedArray<Element>]).ravel() }
        
        let axes = Set(axes).sort() // Filter out any repeated axes.
        guard !axes.contains({ !checkBounds($0, forCount: rank) }) else { fatalError("All axes must be between 0..<rank") }
        
        let newShape = [Int](shape.enumerate().lazy.filter { !axes.contains($0.index) }.map { $0.element })
        
        let internalIndicesList = makeRowMajorIndexGenerator(newShape).map { newIndices -> [ArrayIndex] in
            var internalIndices = newIndices.map { ArrayIndex.SingleValue($0) }
            for a in axes {
                internalIndices.insert(.All, atIndex: a) // N.B. This only works when the axes are sorted.
            }
            return internalIndices
        }
        
        return ComputedArray(shape: newShape, linear: { ComputedArray(self[internalIndicesList[$0]]) })
    }
    
}

// MARK: - Disclose
public extension Array where Element: Array {
    
    func discloseEager() -> ComputedArray<Element.Element> {
        let newShape = shape + self.allElements.first!.shape
        let baseArray = self.allElements.flatMap { $0.allElements }
        return ComputedArray(DenseArray(shape: newShape, baseArray: baseArray))
    }
    
    func disclose() -> ComputedArray<Element.Element> {
        let newShape = shape + self.allElements.first!.shape
        return ComputedArray(shape: newShape, cartesian: { indices in
            let subArray = self[[Int](indices[0..<self.rank])]
            return subArray[[Int](indices[self.rank..<indices.count])]
        })
    }
    
    func discloseFirst() -> ComputedArray<Element.Element> {
        let newShape = self.allElements.first!.shape + shape
        return ComputedArray(shape: newShape, cartesian: { indices in
            let subArray = self[[Int](indices[indices.count - self.rank..<indices.count])]
            return subArray[[Int](indices[0..<indices.count - self.rank])]
        })
    }
    
}