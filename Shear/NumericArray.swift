//
//  NumericArray.swift
//  Sheep
//
//  Created by Andrew Snow on 7/11/15.
//  Copyright © 2015 Andrew Snow. All rights reserved.
//

import Foundation
import Accelerate

// TODO: Consider overload these so that a default type can be inferred.

public func ones<Element: NumericType>(shape newShape: [Int]) -> DenseArray<Element> {
    return DenseArray<Element>(shape: newShape, repeatedValue: 1)
}

public func zeros<Element: NumericType>(shape newShape: [Int]) -> DenseArray<Element> {
    return DenseArray<Element>(shape: newShape, repeatedValue: 0)
}

public func eye<Element: NumericType>(count: Int, rank: Int = 2) -> DenseArray<Element> {
    guard rank > 1 else { return DenseArray<Element>(shape: [1], baseArray: [1]) }
    
    let shape = Swift.Array(count: rank, repeatedValue: count)
    var array: DenseArray<Element> = zeros(shape: shape)
    for i in 0..<count {
        let indices = Swift.Array(count: rank, repeatedValue: i)
        array[indices] = 1
    }
    return array
}

public func eye<Element: NumericType>(shape newShape: [Int]) -> DenseArray<Element> {
    var array: DenseArray<Element> = zeros(shape: newShape)
    let count = newShape.minElement()!
    
    for i in 0..<count {
        let indices = Swift.Array(count: newShape.count, repeatedValue: i)
        array[indices] = 1
    }
    
    return array
}

public func iota<Element: NumericType>(count: Int) -> DenseArray<Element> {
    let range = Range(0..<count)
    return DenseArray<Element>(shape: [count], baseArray: range.map { $0 as! Element })
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