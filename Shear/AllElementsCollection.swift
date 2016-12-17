// Copyright 2016 The Shear Authors. All rights reserved.
// Use of this source code is governed by a MIT-style
// license that can be found in the LICENSE file.

import Foundation
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l >= r
  default:
    return !(lhs < rhs)
  }
}


/// AllElementsCollection is a collection
struct AllElementsCollection<A: TensorProtocol>: Collection, BidirectionalCollection, RandomAccessCollection {
    
    let array: A
    let stride: [Int]
    let count: Int
    
    init(array: A) {
        self.array = array
        stride = calculateStride(array.shape)
        count = array.shape.isEmpty ? 1 : array.shape.reduce(*)
    }
    
    public func index(after i: Int) -> Int {
        return i + 1
    }
    
    func index(before i: Int) -> Int {
        return i - 1
    }
    
    var startIndex: Int {
        return 0
    }
    
    var endIndex: Int {
        return count
    }
    
    subscript(_ position: Int) -> A.Element {
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
        case `nil`
        case ignore
        case fatalError
    }
    
    fileprivate let bounds: [Int]
    fileprivate(set) var current: [Int]?
    fileprivate let onOverflow: OverflowBehavior
    
    init(bounds: [Int], onOverflow: OverflowBehavior) {
        self.bounds = bounds
        self.current = [Int](repeating: 0, count: bounds.count)
        self.onOverflow = onOverflow
    }
    
    mutating func add(_ amount: Int, position pos: Int = 0) {
        guard pos < bounds.count else {
            switch onOverflow {
            case .nil: current = nil; fallthrough
            case .ignore: return
            case .fatalError: fatalError("overflow")
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
func makeRowMajorIndexGenerator(_ shape: [Int]) -> AnyIterator<[Int]> {
    var accRev = BoundedAccumulator(bounds: shape.reversed(), onOverflow: .nil)
    return AnyIterator { () -> [Int]? in
        let elementRev = accRev.current
        accRev.inc()
        return elementRev?.reversed()
    }
}

func makeColumnMajorIndexGenerator(_ shape: [Int]) -> AnyIterator<[Int]> {
    var accRev = BoundedAccumulator(bounds: shape, onOverflow: .nil)
    return AnyIterator { () -> [Int]? in
        let elementRev = accRev.current
        accRev.inc()
        return elementRev
    }
}
