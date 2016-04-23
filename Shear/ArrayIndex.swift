// Copyright 2016 The Shear Authors. All rights reserved.
// Use of this source code is governed by a MIT-style
// license that can be found in the LICENSE file.

import Foundation

public enum ArrayIndex: IntegerLiteralConvertible, ArrayLiteralConvertible {
    
    case All
    case SingleValue(Int)
    case Range(Int, Int)
    case List([Int])
    
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
            return startIndex <= endIndex && endIndex <= bound
        case .List(let indices):
            return indices.filter {$0 >= bound}.isEmpty
        }
    }
    
}

// "RangeLiteralConvertibles" of a sort.
public func ..<(start: Int, end: Int) -> ArrayIndex {
    precondition(start <= end, "ArrayIndex.Range: start must be less than or equal to end")
    return .Range(start, end)
}

public func ...(start: Int, end: Int) -> ArrayIndex {
    return start ..< (end + 1)
}

public let $ = ArrayIndex.All // TODO: decide if this or nil or some other symbol is best to express grabbing all of a dim
