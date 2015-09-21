//
//  AllElementsCollection.swift
//  Shear
//
//  Created by Andrew Snow on 9/20/15.
//  Copyright © 2015 Andrew Snow. All rights reserved.
//

import Foundation

struct AllElementsCollection<A: Array>: CollectionType {
    
    let array: A
    let boundsRev: [Int]
    let strideRev: [Int]
    
    init(array: A) {
        self.array = array
        boundsRev = array.shape.reverse()
        strideRev = calculateStrideRowMajor(boundsRev)
    }
    
    func generate() -> AnyGenerator<A.Element> {
        var accRev = BoundedAccumulator(bounds: boundsRev, onOverflow: .Nil)
        let indexGenerator = anyGenerator { () -> [Int]? in
            let elementRev = accRev.current
            accRev.inc()
            return elementRev?.reverse()
        }
        
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
        return self.array[strideRev.map { position % $0 }]
    }
    
}

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
        while current?[pos] > bounds[pos] {
            current?[pos] -= bounds[pos]
            self.add(1, position: pos + 1)
        }
    }
    
    mutating func inc() {
        add(1, position: 0)
    }
}
