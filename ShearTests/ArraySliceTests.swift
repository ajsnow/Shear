// Copyright 2016 The Shear Authors. All rights reserved.
// Use of this source code is governed by a MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import Shear

class ArraySliceTests: XCTestCase {
    
    let iotaVec = iota(8)
    let iotaSq = iota(16).reshape([4, 4])
    let iotaCube = iota(27).reshape([3, 3, 3])
    let vEvens = iota(4) * 2
    let vOdds = iota(4) * 2 + 1
    let FiveFactorial = iota(120).reshape([1, 2, 3, 1, 4, 5, 1, 1])
    let Scalar = iota(1)
    
    var denseArrays: [DenseArray<Int>] = []
    var allArrays: [Shear.ArraySlice<Int>] = []
    
    override func setUp() {
        super.setUp()
        denseArrays = [iotaVec, iotaSq, iotaCube, vEvens, vOdds, FiveFactorial, Scalar]
        allArrays = denseArrays.map { ArraySlice(baseArray: $0) }
    }
    
    func testInits() {
        let ba = iota(10).reshape([5, 2])
        let fda = Shear.ArraySlice(baseArray: ba)
        let pda = Shear.ArraySlice(baseArray: ba, viewIndices: [$, $])
        let fsa = Shear.ArraySlice(baseArray: pda)
        let psa = Shear.ArraySlice(baseArray: fsa, viewIndices: [$, $])
        
        let arrays = [fda, pda, fsa, psa]
        arrays.forEach {
            XCTAssert($0.shape == [5, 2])
        }
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
            [Int](0..<120),
            [0]
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
    
    func testLinearIndexAssignment() {
        var eight = DenseArray(shape: [1, 2, 4, 11], repeatedValue: "8")[$, $, $]
        XCTAssert(eight[linear: 55] == "8")
        eight[linear: 55] = "55"
        XCTAssert(eight[linear: 55] == "55")
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
        
        zip(allArrays, spotChecks).forEach { (array, checks) in
            checks.forEach { (indices, value) in
                XCTAssertEqual(array[indices], value)
            }
        }
    }
    
    func testScalarIndexAssignment() {
        var eight = DenseArray(shape: [1, 2, 4, 11], repeatedValue: "8")[$, $, $]
        XCTAssert(eight[0, 2, 5] == "8")
        eight[0, 2, 5] = "025"
        XCTAssert(eight[0, 2, 5] == "025")
    }
    
    // MARK: - Slicing
    
    func testSliceIndexingFull() {
        let testVec = allArrays.map { $0.shape.map { _ in $ } }
        
        zip(allArrays, testVec).forEach { (array, indices) in
            XCTAssert(array[indices] == array)
        }
    }
    
    func testSliceIndexingSingular() {
        // First value
        let testVec = allArrays.map { $0.shape.map { _ in ArrayIndex.SingleValue(0) } }
        
        zip(allArrays, testVec).forEach { (array, indices) in
            XCTAssert(Array(array[indices].allElements) == [array.allElements.first!])
        }
        
        // Last value
        let testVec2 = allArrays.map { $0.shape.map { count in ArrayIndex.SingleValue(count - 1) } }
        
        zip(allArrays, testVec2).forEach { (array, indices) in
            XCTAssert(Array(array[indices].allElements) == [array.allElements.last!])
        }
        
        
        let randish = 893746573 // Arbitrary value that won't change between test runs.
        let indices = allArrays.map { $0.shape.map { count in randish % count } }
        let testVec3 = indices.map { $0.map { ArrayIndex.SingleValue($0) } }
        
        let values = zip(allArrays, indices).map { $0[$1] }
        let slices = zip(allArrays, testVec3).map { $0[$1] }
        
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
        
        zip(allArrays, testVec).forEach { (array, test) in
            let slice = array[test.0]
            XCTAssert(slice.allElements.first == test.1.0)
            XCTAssert(slice.allElements.last == test.1.1)
        }
    }
    
    func testSliceIndexingList() {
        let testVec: [([ArrayIndex], (Int, Int))] = [
            ([[7, 3]], (7, 3)),
            ([[0, 3], [2, 3]], (2, 15)),
            ([[2, 1, 0], [1], [2, 1]], (23, 4)),
            ([[0, 1, 3]], (0, 6)),
            ([[1, 2]], (3, 5)),
            ([[0, 1], [0, 2], [2, 3], [3]], (13, 118)),
            ([], (0, 0))
        ]
        
        zip(allArrays, testVec).forEach { (array, test) in
            let slice = array[test.0]
            XCTAssert(slice.allElements.first == test.1.0)
            XCTAssert(slice.allElements.last == test.1.1)
        }
    }
    
    func testSliceIndexingBetweenNestedSlices() {
        let baseArray = iota(3125).reshape([5, 5, 5, 5, 5])
        let firstSlice = baseArray[$, [4, 1, 3, 2], 1..<4, 4, 0]
        XCTAssert(firstSlice.shape == [5, 4, 3])
        
        let view = [$, 1, 1..<3, [2, 0]]
        
        
        let views = (0..<4).map {
            Array(view.rotate($0).dropLast())
        }
        
        // !!! n.b. this is just codifying the results as they exist so as to detect changes in behavior.
        // At somepoint, I will need to actually check these results really are _correct_ !!!
        let expectedResults = [
            [195, 220, 820, 845, 1445, 1470, 2070, 2095, 2695, 2720].reshape([5, 2]),
            [845, 795, 1095, 1045].reshape([2, 2]),
            [1045, 1070, 1095, 1170, 1195, 1220, 1670, 1695, 1720, 1795, 1820, 1845].reshape([2, 2, 3]),
            [1820, 1445, 1695, 1570, 570, 195, 445, 320].reshape([2, 4]),
        ]
        
        zip(views, expectedResults).forEach { (view, result) in
            let secondSlice = firstSlice[view]
            XCTAssert(secondSlice == result)
        }
    }
    
}
