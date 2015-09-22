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
    
    // Maintain a mutable reference to our parent array through the power of abusing closures!
    let arrayIndex: ([Int]) -> A.Element
    let subscriptGet: (Int) -> A.Element
    let subscriptSet: (Int, A.Element) -> Void
    let arrayCount: () -> Int
    
    let boundsRev: [Int]
    
    init(inout array: A) {
        let stride = calculateStrideRowMajor(array.shape)
        
        // This seems like I'm asking for trouble...
        self.arrayIndex = { array[$0] }
        
        self.subscriptGet = { (position: Int) -> A.Element in
            return array[stride.map { position % $0 }]
        }
        
        self.subscriptSet = { (position: Int, value: A.Element) -> Void in
            array[stride.map { position % $0 }] = value
        }
        
        self.arrayCount = { array.shape.reduce(1, combine: *) }
        
        // We reverse the bounds so that we can reverse the BoundedAccumulator's output.
        // We reverse that because we need row major order, which means incrementing the rows (indices.first) last.
        boundsRev = array.shape.reverse()
    }
    
    // We could just go from startIndex to endIndex - 1 with subscriptSet
    func generate() -> AnyGenerator<A.Element> {
        var accRev = BoundedAccumulator(bounds: boundsRev, onOverflow: .Nil)
        let indexGenerator = anyGenerator { () -> [Int]? in
            let elementRev = accRev.current
            accRev.inc()
            return elementRev?.reverse()
        }
        
        return anyGenerator { () -> A.Element? in
            guard let indices = indexGenerator.next() else { return nil }
            return self.arrayIndex(indices)
        }
    }
    
    var count: Int {
        return arrayCount()
    }
    
    var startIndex: Int {
        return 0
    }
    
    var endIndex: Int {
        return count
    }
    
    subscript(position: Int) -> A.Element {
        get {
            return subscriptGet(position)
        }
        set(newValue) {
           subscriptSet(position, newValue)
        }
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
private struct BoundedAccumulator {
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
