// Copyright 2016 The Shear Authors. All rights reserved.
// Use of this source code is governed by a MIT-style
// license that can be found in the LICENSE file.

import Foundation

public enum TensorIndex: ExpressibleByIntegerLiteral, ExpressibleByArrayLiteral {
    
    case all
    case singleValue(Int)
    case range(Int, Int)
    case list([Int])
    
    public init(integerLiteral value: Int) {
        self = .singleValue(value)
    }
    
    public init(arrayLiteral elements: Int...) {
        self = .list(elements)
    }
    
    func isInbounds(_ bound: Int) -> Bool {
        switch self {
        case .all:
            return true
        case .singleValue(let index):
            return index < bound
        case .range(let startIndex, let endIndex):
            return startIndex <= endIndex && endIndex <= bound
        case .list(let indices):
            return !indices.contains { $0 >= bound }
        }
    }
    
}

// "RangeLiteralConvertibles" of a sort.
public func ..<(start: Int, end: Int) -> TensorIndex {
    precondition(start <= end, "TensorIndex.Range: start must be less than or equal to end")
    return .range(start, end)
}

public func ...(start: Int, end: Int) -> TensorIndex {
    return start ..< (end + 1)
}

//public let $ = TensorIndex.all // TODO: decide if this or nil or some other symbol is best to express grabbing all of a dim
