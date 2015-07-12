//
//  Array.swift
//  Sheep
//
//  Created by Andrew Snow on 6/14/15.
//  Copyright © 2015 Andrew Snow. All rights reserved.
//

import Foundation

public protocol Array: SequenceType {
    typealias Element
    
    var shape: [Int] { get }
    var rank: Int { get }
    
    subscript(indices: Int...) -> Element { get set }
    
    init(shape newShape: [Int], repeatedValue: Element)
    init(shape newShape: [Int], baseArray: [Element])
    init<A: Array where A.Generator.Element == Element>(shape newShape: [Int], baseArray: A)
}
