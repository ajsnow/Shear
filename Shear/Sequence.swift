// Copyright 2016 The Shear Authors. All rights reserved.
// Use of this source code is governed by a MIT-style
// license that can be found in the LICENSE file.

import Foundation

// MARK: - Sequence
public extension Array {
    
    /// Slices the Array into a sequence of `ArraySlice`s on its nth `deminsion`.
    func sequence(deminsion: Int) -> [ArraySlice<Element>] {
        if (isEmpty || isScalar) && deminsion == 0 { // TODO: Consider making sequencing scalar or empty arrays an error.
            return [ArraySlice(baseArray: self)]
        }
        guard deminsion < rank else { fatalError("An array cannot be sequenced on a deminsion it does not have") }
        
        let viewIndices = [ArrayIndex](count: rank, repeatedValue: ArrayIndex.All)
        return (0..<shape[deminsion]).map {
            var nViewIndices = viewIndices
            nViewIndices[deminsion] = .SingleValue($0)
            return self[nViewIndices]
        }
    }
    
    /// Slices the Array on its first dimension.
    /// Since our DenseArray is stored in Row-Major order, sequencing on the first
    /// dimension allows for better memory access patterns than any other sequence.
    var sequenceFirst: [ArraySlice<Element>] {
        return sequence(0)
    }
    
    /// Slices the Array on its last dimension.
    /// Tends to not be cache friendly...
    var sequenceLast: [ArraySlice<Element>] {
        return sequence(rank != 0 ? rank - 1 : 0)
    }
    
    /// Returns a sequence containing pairs of cartesian indices and `Element`s.
    public func coordinate() -> AnySequence<([Int], Element)> {
        let indexGenerator = makeRowMajorIndexGenerator(shape)
        
        return AnySequence(AnyGenerator {
            guard let indices = indexGenerator.next() else { return nil }
            return (indices, self[indices]) // TODO: Linear indexing is cheaper for DenseArrays. Consider specializing.
            })
    }
    
}