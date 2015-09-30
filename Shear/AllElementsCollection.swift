//
//  AllElementsCollection.swift
//  Shear
//
//  Created by Andrew Snow on 9/20/15.
//  Copyright © 2015 Andrew Snow. All rights reserved.
//

import Foundation

/// AllElementsCollection is a collection
struct AllElementsCollection<A: Array>: CollectionType {
    
    let array: A
    let stride: [Int]
    
    init(array: A) {
        self.array = array
        stride = calculateStrideRowMajor(array.shape)
    }
    
    func generate() -> AnyGenerator<A.Element> {
        
        let indexGenerator = makeRowMajorIndexGenerator(array.shape)
        
        return anyGenerator { () -> A.Element? in
            guard let indices = indexGenerator.next() else { return nil }
            return self.array[indices]
        }
    }
    
    var count: Int {
        return array.shape.reduce(1, combine: *)
    }
    
    var startIndex: Int {
        return 0
    }
    
    var endIndex: Int {
        return count
    }
    
    subscript(position: Int) -> A.Element {
        return self.array[stride.map { position % $0 }]
    }
    
}

/// BoundedAccumulator is a generalization of binary addition to cover non-binary, non-uniform-capacity digits.
/// E.g.
///     var a = BoundedAccumulator([4, 2, 5], onOverflow: .Ignore)
///               # a.current == [0, 0, 0]
///     a.inc()   # a.current == [1, 0, 0]
///     a.add(10) # a.current == [3, 0, 1]
///
/// We use it to convert linear indices into their cartesian equivilants.
/// (N.B. this requires setting the bounds to the reversed shape & reversing the output since our mapping is row-major.)
struct BoundedAccumulator {
    enum OverflowBehavior {
        case Nil
        case Ignore
        case FatalError
    }
    
    private let bounds: [Int]
    private(set) var current: [Int]?
    private let onOverflow: OverflowBehavior
    
    init(bounds: [Int], onOverflow: OverflowBehavior) {
        self.bounds = bounds
        self.current = Swift.Array(count: bounds.count, repeatedValue: 0)
        self.onOverflow = onOverflow
    }
    
    mutating func add(amount: Int, position pos: Int = 0) {
        guard pos < bounds.count else {
            switch onOverflow {
            case .Nil: current = nil; fallthrough
            case .Ignore: return
            case .FatalError: fatalError("overflow")
            }
        }
        
        current?[pos] += amount
        while current?[pos] >= bounds[pos] {
            current?[pos] -= bounds[pos]
            self.add(1, position: pos + 1)
        }
    }
    
    mutating func inc() {
        add(1, position: 0)
    }
}

// We reverse the shape so that we can reverse the BoundedAccumulator's output.
// We reverse that because we need row major order, which means incrementing the rows (indices.first) last.
func makeRowMajorIndexGenerator(shape: [Int]) -> AnyGenerator<[Int]> {
    var accRev = BoundedAccumulator(bounds: shape.reverse(), onOverflow: .Nil)
    return anyGenerator { () -> [Int]? in
        let elementRev = accRev.current
        accRev.inc()
        return elementRev?.reverse()
    }
}