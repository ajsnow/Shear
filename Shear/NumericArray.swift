//
//  NumericArray.swift
//  Sheep
//
//  Created by Andrew Snow on 7/11/15.
//  Copyright © 2015 Andrew Snow. All rights reserved.
//

import Foundation
import Accelerate


// Psudeo-Protocol of NumericArray
extension Array where Element: NumericType {
    public static func Ones(shape newShape: [Int]) -> DenseArray<Element> {
        return DenseArray<Element>(shape: newShape, repeatedValue: 1)
    }

    public static func Zeros(shape newShape: [Int]) -> DenseArray<Element> {
        return DenseArray<Element>(shape: newShape, repeatedValue: 0)
    }
    
    func add<A: Array where A.Element == Self.Element>(right: A) -> DenseArray<Element> {
        return DenseArray(shape: self.shape, baseArray: zip(self.allElements, right.allElements).map(+))
    }

//    public static func Eyes(length: Int, rank: Int = 2) -> DenseArray<Element> {
//        var array = Zeros(shape: Swift.Array(count: rank, repeatedValue: length))
//        for i in 0..<length {
//            let indices = Swift.Array(count: rank, repeatedValue: i)
//            array[indices] = Element(1) // Cannot assign type of Self.Element to a varaible of type Self.Element?
//        }
//        return array
//    }
}

public protocol NumericArray: Array {

    typealias Element: NumericType
//    // Elementwise addition
//    func +(lhs: Self, rhs: Self) -> Self
//
//    // Elementwise subtraction
//    func -(lhs: Self, rhs: Self) -> Self
//    
//    // Elementwise multiplication (Hadamard or Schur product)
//    // OR
//    // Matrix Multiplication
//    func *(lhs: Self, rhs: Self) -> Self
//    func /(lhs: Self, rhs: Self) -> Self
    
    
    // inhereited
    
//    func *(lhs: Self, rhs: Self) -> Self
//    func *(lhs: Self, rhs: NumericArray) -> NumericArray
//    func *(lhs: NumericArray, rhs: Self) -> NumericArray

//    func *(lhs: Element, rhs: Self) -> Self
//    func *(lhs: Self, rhs: Element) -> Self
//    func *=(inout lhs: double2x4, rhs: Double)
//    func *=(inout lhs: double2x4, rhs: double2x2)
    
//    func +(lhs: Self, rhs: Self) -> Self
//    func +=(inout lhs: Self, rhs: Self)
//    func -(lhs: Self, rhs: Self) -> Self
//    prefix func -(rhs: Self) -> Self
//    func -=(inout lhs: Self, rhs: Self)

}


protocol Vector: NumericArray {
    
}

protocol Matrix: NumericArray {
//    var transpose: Matrix { get }
}

protocol SimdArray {
//    *
//    *=
//    +
//    +=
//    -
//    -=
//    /
//    /=
//    abs
//    ceil
//    clamp
//    cross
//    distance
//    distance_squared
//    dot
//    floor
//    fmax
//    fmin
//    fract
//    length
//    length_squared
//    max
//    min
//    mix
//    norm_inf
//    norm_one
//    normalize
//    project
//    recip
//    reduce_add
//    reduce_max
//    reduce_min
//    reflect
//    refract
//    rsqrt
//    sign
//    smoothstep
//    step
//    trunc
//    prefix -
}

//extension double2x4: Array {
//    public typealias Element = Double
//    
//    public var shape: [Int] { return [2, 4] }
//    public var rank: Int { return 2 }
//}
//
//extension double2x4: NumericArray {
//    
//}