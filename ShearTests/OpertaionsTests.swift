// Copyright 2016 The Shear Authors. All rights reserved.
// Use of this source code is governed by a MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import Shear

class OpertaionsTests: XCTestCase {

    let iotaVec = iota(8)
    let iotaSq = iota(16).reshape([4, 4])
    let iotaCube = iota(27).reshape([3, 3, 3])
    let vEvens = iota(4) * 2
    let vOdds = iota(4) * 2 + 1
    let FiveFactorial = iota(120).reshape([1, 2, 3, 1, 4, 5, 1, 1])
    let Scalar = iota(1)

    var allArrays: [DenseArray<Int>] = []
    
    override func setUp() {
        super.setUp()
        allArrays = [iotaVec, iotaSq, iotaCube, vEvens, vOdds, FiveFactorial, Scalar]
    }
    
    func testSequence() {
        let correctValues: [(Shear.DenseArray<Int>, Shear.DenseArray<Int>)] = [
            ([0].ravel(), [7].ravel()),
            ([0, 1, 2, 3].ravel(), [3, 7, 11, 15].ravel()),
            (iota(9).reshape([3, 3]), [2, 5, 8, 11, 14, 17, 20, 23, 26].reshape([3, 3])),
            ([0].ravel(), [6].ravel()),
            ([1].ravel(), [7].ravel()),
            (iota(60).reshape([3, 4, 5]), [4, 9, 14, 19, 24, 29, 34, 39, 44, 49, 54, 59, 64, 69, 74, 79, 84, 89, 94, 99, 104, 109, 114, 119].reshape([2, 3, 4])),
            ([0].ravel(), [0].ravel()),
        ]
        
        zip(allArrays, correctValues).forEach {
            XCTAssert($0.0.sequenceFirst.first! == $0.1.0)
            XCTAssert($0.0.sequenceLast.last! == $0.1.1)
        }
        
    }
    
    func testReshape() {
        let testVectors: [([Int], Shear.DenseArray<Int>)] = [
            ([2, 4], DenseArray(shape: [2, 4], baseArray: iota(8))),
            ([16], iota(16)),
            ([1, 3, 1, 1, 1, 9, 1], DenseArray(shape: [3, 9], baseArray: iota(27))),
            ([2, 2], DenseArray(shape: [2, 2], baseArray: [0, 2, 4, 6])),
            ([1, 4], DenseArray(shape: [4, 1], baseArray: [1, 3, 5, 7])),
        ]
        
        zip(allArrays, testVectors).forEach {
            XCTAssert($0.0.reshape($0.1.0) == $0.1.1)
        }
    }
    
    func testRavel() {
        let correctValues = [
            iota(8),
            iota(16),
            iota(27),
            iota(4) * 2,
            iota(4) * 2 + 1,
            iota(120),
            iota(1),
        ]
        
        zip(allArrays, correctValues).forEach {
            XCTAssert($0.0.ravel() == $0.1)
        }
    }
    
    func testEnclose() {
        // test vecs will be hard for this one since it takes ints instead of [int]
        XCTAssert(false)
    }
    
    func testFlip() {
        XCTAssert(false)
    }
    
}
