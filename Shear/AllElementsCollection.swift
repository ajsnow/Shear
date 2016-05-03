// Copyright 2016 The Shear Authors. All rights reserved.
// Use of this source code is governed by a MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// AllElementsCollection is a collection
struct AllElementsCollection<A: TensorProtocol>: CollectionType {
    
    let array: A
    let stride: [Int]
    let count: Int
    
    init(array: A) {
        self.array = array
        stride = calculateStride(array.shape)
        count = array.shape.isEmpty ? 1 : array.shape.reduce(*)
    }
    
    func generate() -> AnyGenerator<A.Element> {
        
        let indexGenerator = makeRowMajorIndexGenerator(array.shape)
        
        return AnyGenerator { () -> A.Element? in
            guard let indices = indexGenerator.next() else { return nil }
            return self.array[indices]
        }
    }
    
    var startIndex: Int {
        return 0
    }
    
    var endIndex: Int {
        return count
    }
    
    subscript(position: Int) -> A.Element {
        return array[linear: position]
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
        self.current = [Int](count: bounds.count, repeatedValue: 0)
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
    return AnyGenerator { () -> [Int]? in
        let elementRev = accRev.current
        accRev.inc()
        return elementRev?.reverse()
    }
}

func makeColumnMajorIndexGenerator(shape: [Int]) -> AnyGenerator<[Int]> {
    var accRev = BoundedAccumulator(bounds: shape, onOverflow: .Nil)
    return AnyGenerator { () -> [Int]? in
        let elementRev = accRev.current
        accRev.inc()
        return elementRev
    }
}
