// Copyright 2016 The Shear Authors. All rights reserved.
// Use of this source code is governed by a MIT-style
// license that can be found in the LICENSE file.

import XCTest
import Shear

class TensorBasicsTests: XCTestCase {

    let iotaVec = iota(8)
    let iotaSq = iota(16).reshape([4, 4])
    let iotaCube = iota(27).reshape([3, 3, 3])
    let vEvens = iota(4) * 2
    let vOdds = iota(4) * 2 + 1
    let FiveFactorial = iota(120).reshape([1, 2, 3, 1, 4, 5, 1, 1])
    let Scalar = iota(1)
    
    var allTensors: [Tensor<Int>] = []
    
    override func setUp() {
        super.setUp()
        allTensors = [iotaVec, iotaSq, iotaCube, vEvens, vOdds, FiveFactorial, Scalar]
    }

    // MARK: Basics - from TensorProtocol.swift
    func testRank() {
        let correctValues = [
            1,
            2,
            3,
            1,
            1,
            4,
            0,
        ]
        
        zip(allTensors, correctValues).forEach {
            XCTAssertEqual($0.0.rank, $0.1)
        }
    }
    
    func testIsEmpty() {
        allTensors.forEach {
            XCTAssertEqual($0.isEmpty, false) // Empty arrays are not allowed.
        }
    }
    
    func testIsScalar() {
        let correctValues: [(Bool, Int?)] = [
            (false, nil),
            (false, nil),
            (false, nil),
            (false, nil),
            (false, nil),
            (false, nil),
            (true, 0)
        ]
        
        zip(allTensors, correctValues).forEach {
            XCTAssertEqual($0.0.isScalar, $0.1.0)
            XCTAssertEqual($0.0.scalar, $0.1.1)
        }
    }
    
    
    func testIsVector() {
        let correctValues = [
            true,
            false,
            false,
            true,
            true,
            false,
            false
        ]
        
        zip(allTensors, correctValues).forEach {
            XCTAssertEqual($0.0.isVector, $0.1)
        }
    }
    
    func testEquality() {
        // Test self equality & self not-inequality
        allTensors.forEach {
            XCTAssert($0 == $0)
            XCTAssert(!($0 != $0))
        }
        
        // Test copy equality and not-inequality
        allTensors.forEach {
            let copy = $0
            XCTAssert(copy == $0)
            XCTAssert(!(copy != $0))
            XCTAssert($0 == copy)
            XCTAssert(!($0 != copy))
        }
        
        // Test identical value equality and not-inequality
        let newTensors = [
            iota(8),
            iota(16).reshape([4, 4]),
            iota(27).reshape([3, 3, 3]),
            iota(4) * 2,
            iota(4) * 2 + 1,
            iota(120).reshape([1, 2, 3, 1, 4, 5, 1, 1]),
            iota(1)
        ]
        zip(allTensors, newTensors).forEach {
            XCTAssert($0.0 == $0.1)
            XCTAssert(!($0.0 != $0.1))
        }
        
        // Test inequality and not-equality
        let offByOne = newTensors[1..<newTensors.count] + [newTensors[0]]
        zip(allTensors, offByOne).forEach {
            XCTAssert($0.0 != $0.1)
            XCTAssert(!($0.0 == $0.1))
        }
        
    }
    
    func testCustomStringConvertible() {
        let correctValues = [
            "A{[0, 1, 2, 3, 4, 5, 6, 7]}",
            "A{[[0, 1, 2, 3], [4, 5, 6, 7], [8, 9, 10, 11], [12, 13, 14, 15]]}",
            "A{[[[0, 1, 2], [3, 4, 5], [6, 7, 8]], [[9, 10, 11], [12, 13, 14], [15, 16, 17]], [[18, 19, 20], [21, 22, 23], [24, 25, 26]]]}",
            "A{[0, 2, 4, 6]}",
            "A{[1, 3, 5, 7]}",
            "A{[[[[0, 1, 2, 3, 4], [5, 6, 7, 8, 9], [10, 11, 12, 13, 14], [15, 16, 17, 18, 19]], [[20, 21, 22, 23, 24], [25, 26, 27, 28, 29], [30, 31, 32, 33, 34], [35, 36, 37, 38, 39]], [[40, 41, 42, 43, 44], [45, 46, 47, 48, 49], [50, 51, 52, 53, 54], [55, 56, 57, 58, 59]]], [[[60, 61, 62, 63, 64], [65, 66, 67, 68, 69], [70, 71, 72, 73, 74], [75, 76, 77, 78, 79]], [[80, 81, 82, 83, 84], [85, 86, 87, 88, 89], [90, 91, 92, 93, 94], [95, 96, 97, 98, 99]], [[100, 101, 102, 103, 104], [105, 106, 107, 108, 109], [110, 111, 112, 113, 114], [115, 116, 117, 118, 119]]]]}",
            "A{0}"
        ]
        
        zip(allTensors, correctValues).forEach {
            XCTAssert(String(describing: $0.0) == $0.1)
        }
    }

}
