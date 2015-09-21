//
//  SwiftExtensions.swift
//  Shear
//
//  Created by Andrew Snow on 9/15/15.
//  Copyright © 2015 Andrew Snow. All rights reserved.
//

import Foundation

extension Swift.Array {
    var shear: DenseArray<Element> {
        return DenseArray(shape: [count], baseArray: self)
    }
}