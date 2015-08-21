//
//  ArrayIndex.swift
//  Shear
//
//  Created by Andrew Snow on 8/10/15.
//  Copyright © 2015 Andrew Snow. All rights reserved.
//

import Foundation

public enum ArrayIndex: NilLiteralConvertible, IntegerLiteralConvertible, ArrayLiteralConvertible {
    
    case All
    case SingleValue(Int)
    case Range(Int, Int)
    case List([Int])
    
    public init(nilLiteral: ()) {
        self = .All
    }
    
    public init(integerLiteral value: Int) {
        self = .SingleValue(value)
    }
    
    public init(arrayLiteral elements: Int...) {
        self = .List(elements)
    }
    
    func isInbounds(bound: Int) -> Bool {
        switch self {
        case .All:
            return true
        case .SingleValue(let index):
            return index < bound
        case .Range(let startIndex, let endIndex):
            return startIndex <= endIndex && endIndex < bound
        case .List(let indices):
            return indices.filter {$0 >= bound}.isEmpty
        }
    }
    
}

// A "RangeLiteralConvertible" of a sort.
func ..<(start: Int, end: Int) -> ArrayIndex {
    precondition(start <= end, "ArrayIndex.Range: start must be less than or equal to end")
    return .Range(start, end)
}

let $ = ArrayIndex.All // TODO: decide if this or nil or some other symbol is best to express grabbing all of a dim
