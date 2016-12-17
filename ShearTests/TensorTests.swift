// Copyright 2016 The Shear Authors. All rights reserved.
// Use of this source code is governed by a MIT-style
// license that can be found in the LICENSE file.

import XCTest
import Shear

class TensorTests: XCTestCase {
    
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
    
    func testInits() {
        let six = Tensor(shape: [1, 1, 2, 1, 3, 1], repeatedValue: "Six")
        XCTAssert(six.shape == [2, 3])
        XCTAssert(six.allElements.count == 6)
        for str in six.allElements {
            XCTAssert(str == "Six")
        }
        
        let one = Tensor(shape: [], repeatedValue: "One")
        XCTAssert(one.shape == [])
        XCTAssert(one.allElements.count == 1)
        for str in one.allElements {
            XCTAssert(str == "One")
        }
        
        let iota2x3 = Tensor(shape: [2, 1, 3], values: [0, 1, 2, 3, 4, 5, 6])
        XCTAssert(iota2x3 == iota(6).reshape([2, 3]))

        let iota1 = Tensor(shape: [], values: [0])
        XCTAssert(iota1 == iota(1))

        let iota3x2 = Tensor(shape: [3, 2, 1, 1, 1], tensor: iota2x3)
        XCTAssert(iota3x2 == iota(6).reshape([3, 2]))
        
        let iota1b = Tensor(shape: [], tensor: iota1)
        XCTAssert(iota1b == iota1)
        
        let tensorify = Tensor(iota2x3[.all, .all])
        XCTAssert(tensorify == iota2x3)
        
        let iota1c = Tensor(iota1[[] as [TensorIndex]])
        XCTAssert(iota1c == iota1)
        
        let cordString = Tensor(shape: [2, 3], cartesian: { indices in indices.reduce("", {$0 + String($1) }) })
        let cordString2 = Tensor(shape: [2, 3], values: ["00", "01", "02", "10", "11", "12"])
        XCTAssert(cordString == cordString2)
        
        let index = Tensor(shape: [2, 3], linear: { $0 })
        let index2 = Tensor(shape: [2, 3], values: [0, 1, 2, 3, 4, 5])
        XCTAssert(index == index2)
        
    }
    
    func testShape() {
        let correctBehavior = [
            [8],
            [4, 4],
            [3, 3, 3],
            [4],
            [4],
            [2, 3, 4, 5],
            []
        ]
        
        zip(allTensors, correctBehavior).forEach {
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
            [Int](0..<120),
            [0]
        ]
        
        zip(allTensors, correctBehavior).forEach {
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
            [([], 0)]
        ]
        
        zip(allTensors, spotChecks).forEach { (array, checks) in
            checks.forEach { (indices, value) in
                XCTAssertEqual(array[indices], value)
            }
        }
    }
    
    // MARK: - Slicing
    
    func testSliceIndexingFull() {
        let testVec = allTensors.map { $0.shape.map { _ in TensorIndex.all } }
        
        zip(allTensors, testVec).forEach { (array, indices) in
            XCTAssert(array[indices] == array)
        }
    }
    
    func testSliceIndexingSingular() {
        // First value
        let testVec = allTensors.map { $0.shape.map { _ in TensorIndex.singleValue(0) } }
        
        zip(allTensors, testVec).forEach { (array, indices) in
            XCTAssert(Array(array[indices].allElements) == [array.allElements.first!])
        }
        
        // Last value
        let testVec2 = allTensors.map { $0.shape.map { count in TensorIndex.singleValue(count - 1) } }
        
        zip(allTensors, testVec2).forEach { (array, indices) in
            XCTAssert(Array(array[indices].allElements) == [array.allElements.last!])
        }
        
        
        let randish = 893746573 // Arbitrary value that won't change between test runs.
        let indices = allTensors.map { $0.shape.map { count in randish % count } }
        let testVec3 = indices.map { $0.map { TensorIndex.singleValue($0) } }
        
        let values = zip(allTensors, indices).map { $0[$1] }
        let slices = zip(allTensors, testVec3).map { $0[$1] }
        
        zip(slices, values).forEach { (slice, value) in
            XCTAssert(slice.allElements.first! == value)
        }
    }
    
    func testSliceIndexingRange() {
        let testVec = [
            ([3..<8], (3, 7)),
            ([0...3, 2..<4], (2, 15)),
            ([0..<3, 1...1, 1...2], (4, 23)),
            ([0..<4], (0, 6)),
            ([1...2], (3, 5)),
            ([0..<2, 0...2, 2...3, 3..<4], (13, 118)),
            ([], (0, 0))
        ]
        
        zip(allTensors, testVec).forEach { (array, test) in
            let slice = array[test.0]
            XCTAssert(slice.allElements.first == test.1.0)
            XCTAssert(slice.allElements.last == test.1.1)
        }
    }
    
    func testSliceIndexingList() {
        let testVec: [([TensorIndex], (Int, Int))] = [
            ([[7, 3]], (7, 3)),
            ([[0, 3], [2, 3]], (2, 15)),
            ([[2, 1, 0], [1], [2, 1]], (23, 4)),
            ([[0, 1, 3]], (0, 6)),
            ([[1, 2]], (3, 5)),
            ([[0, 1], [0, 2], [2, 3], [3]], (13, 118)),
            ([], (0, 0))
        ]
        
        zip(allTensors, testVec).forEach { (array, test) in
            let slice = array[test.0]
            XCTAssert(slice.allElements.first == test.1.0)
            XCTAssert(slice.allElements.last == test.1.1)
        }
    }
    
}
