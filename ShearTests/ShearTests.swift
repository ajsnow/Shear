//
//  ShearTests.swift
//  ShearTests
//
//  Created by Andrew Snow on 7/12/15.
//  Copyright © 2015 Andrew Snow. All rights reserved.
//

import XCTest
@testable import Shear

class ShearTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        var z = BoundedAccumulator(bounds: [10], onOverflow: .Nil)
        z.current
        z.add(5)
        z.add(5)
        z.current
        z.add(50)
        z.current
        
        let a = DenseArray(shape: [1, 2, 3, 4, 5], repeatedValue: 0).allElements.count
        
        //print(a)
        
        let b = DenseArray(shape: [3, 4], baseArray: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
        
        //print(b)
        
        let c = DenseArray(shape: [2, 3], baseArray: [0, 1, 2, 3, 4, 5])
        
        print(c)
        
        c[1, 2]
        
        let d = c[$, [0, 2]]
        //let d = ArraySlice(baseArray: c, viewIndices: [nil, [0, 2]])
        
        print(d)
        
        let e = c[$, .All]
        let f = c[nil, 1]
        
        let big = DenseArray(shape: [1, 2, 3, 4, 5], baseArray: Array(0..<120))
        
        big.shape
        big.shape.count
        big.rank
        big.isEmpty
        big.isScalar
        big.isVector
        big.scalar
        
        //let smallish = ArraySlice(baseArray: big, viewIndices: [ArrayIndex.All, .SingleValue(0), .Range(0, 2), .List([0, 2, 3]), .All])
        //let small = ArraySlice(baseArray: smallish, viewIndices: [.SingleValue(0), .Range(0, 2), .List([1, 2])])
        
        let view = big.sequence(1)[1]
        
        view.shape
        view
        
        // MATHS
        
        //inner(0, map: *, lhs: [1, 2, 3], rhs: [4, 5, 6], reduce: +)
        //outer(*, lhs: [1, 2, 3], rhs: [4, 5, 6])
        
        //innerProduct(c, b)
        
        // Vector Inner Product (e.g. dot)
        
        let vecA = DenseArray(shape: [3], baseArray: [1, 2, 3])
        let vecB = DenseArray(shape: [3], baseArray: [9, 10, 11])
        
        //innerProduct(vecA, vecB)
        
        // Matrix Inner Product
        
        let matA = DenseArray(shape: [3, 2], baseArray: [1, 2, 3, 4, 5, 6])
        let matB = DenseArray(shape: [3, 2], baseArray: [9, 10, 11, 12, 13, 14])
        
        //innerProduct(matA, matB) // should be [[62, 80], [152, 197]]
        
        let matC = DenseArray(shape: [2, 3], baseArray: [9, 10, 11, 12, 13, 14])
        
        //innerProduct(matA, matC) // should be error
        
        vecB.reduce(1, combine: *).scalar!
        
        let iotaCube = DenseArray(shape: [2, 2, 2], baseArray: [0, 1, 2, 3, 4, 5, 6, 7])
        iotaCube.reduce(0, combine: +)
        
        let iotaSq = DenseArray(shape: [2, 2], baseArray: [0, 1, 2, 3])
        iotaSq * iotaSq
        
//        inner(iotaSq, right: iotaSq, transform: *, initial: 0, combine: +)
        
//        inner(vecA, right: vecB, transform: *, initial: 0, combine: +)
        
        inner(iotaCube, iotaCube, product: *, sum: +, initialSum: 0)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
