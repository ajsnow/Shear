//
//  ShearTests.swift
//  ShearTests
//
//  Created by Andrew Snow on 7/12/15.
//  Copyright © 2015 Andrew Snow. All rights reserved.
//

import XCTest
import Shear

class DenseArrayTests: XCTestCase {
    
    let iotaVec = iota(8)
    let iotaSq = iota(16).reshape([4, 4])
    let iotaCube = iota(27).reshape([3, 3, 3])
    let vEvens = iota(4) * 2
    let vOdds = iota(4) * 2 + 1
    let FiveFactorial = iota(120).reshape([1, 2, 3, 1, 4, 5, 1, 1])
    
    var allArrays: [DenseArray<Int>] = []
    
    override func setUp() {
        super.setUp()
        allArrays = [iotaVec, iotaSq, iotaCube, vEvens, vOdds, FiveFactorial]
    }
    
    override func tearDown() {
        
        super.tearDown()
    }
    
    func testInits() {
        XCTAssert(false)
    }
    
    func testShape() {
        let correctBehavior = [
            [8],
            [4, 4],
            [3, 3, 3],
            [4],
            [4],
            [2, 3, 4, 5]
        ]
        
        zip(allArrays, correctBehavior).forEach {
            XCTAssertEqual($0.0.shape, $0.1)
        }
    }
    
    func testAllElements() {
        let correctBehavior = [
            [Int](0..<8),
            [Int](0..<16),
            [Int](0..<27),
            [0, 2, 4, 6],
            [1, 3, 5, 7],
            [Int](0..<120)
        ]
        
        zip(allArrays, correctBehavior).forEach {
            XCTAssertEqual($0.0.allElements.map { $0 }, $0.1)
        }
    }
    
    func testLinearIndexing() {
        let spotChecks = [0, 1, 2, 37, 28, 83, 118, 119]
        spotChecks.forEach {
            XCTAssertEqual(FiveFactorial[linear: $0], $0)
        }
    }
    
    func testScalarIndexing() {
        let spotChecks = [
            [([0], 0), ([4], 4)],
            [([2, 1], 9)],
            [([2, 2, 2], 26)],
            [],
            [],
            [([0, 1, 2, 3], 33)],
        ]
        
        zip(allArrays, spotChecks).forEach { (array, checks) in
            checks.forEach { (indices, value) in
                XCTAssertEqual(array[indices], value)
            }
        }
    }
    
    func testSliceIndexing() {
        XCTAssert(false)
    }
    
}
