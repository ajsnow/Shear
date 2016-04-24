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
        // We're only testing the shape is as expected, this does not guarantee the method is actually working, 
        // but it should detect most types of breaking changes to the existing implimentation.
        allArrays.dropLast().forEach { // we drop the last as enclosing scalar won't be fun.
            // Empty enclose
            let enclosedArray = $0.enclose([])
            XCTAssert(enclosedArray.scalar! == $0)
            
            // Enclose with axis
            let encloseFirst = $0.enclose(0)
            XCTAssert(encloseFirst.shape == [Int]($0.shape.dropFirst()))
            XCTAssert(encloseFirst[linear: 0].shape == [$0.shape.first!])
            print(encloseFirst)
            let encloseLast = $0.enclose($0.rank - 1)
            XCTAssert(encloseLast.shape == [Int]($0.shape.dropLast()))
            XCTAssert(encloseLast[linear: 0].shape == [$0.shape.last!])
            print(encloseLast)
        }
        
        // multi-axis enclose
        let multi = FiveFactorial.enclose(1, 2)
        XCTAssert(multi.shape == [2, 5])
        XCTAssert(multi[linear: 0].shape == [3, 4])
    }
    
    func testFlipReverseTransposeRotate() {
        let flipped = [60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59].reshape([2, 3, 4, 5])
        
        XCTAssert(FiveFactorial.flip() == flipped)
        
        let reversed = [4, 3, 2, 1, 0, 9, 8, 7, 6, 5, 14, 13, 12, 11, 10, 19, 18, 17, 16, 15, 24, 23, 22, 21, 20, 29, 28, 27, 26, 25, 34, 33, 32, 31, 30, 39, 38, 37, 36, 35, 44, 43, 42, 41, 40, 49, 48, 47, 46, 45, 54, 53, 52, 51, 50, 59, 58, 57, 56, 55, 64, 63, 62, 61, 60, 69, 68, 67, 66, 65, 74, 73, 72, 71, 70, 79, 78, 77, 76, 75, 84, 83, 82, 81, 80, 89, 88, 87, 86, 85, 94, 93, 92, 91, 90, 99, 98, 97, 96, 95, 104, 103, 102, 101, 100, 109, 108, 107, 106, 105, 114, 113, 112, 111, 110, 119, 118, 117, 116, 115].reshape([2, 3, 4, 5])
        
        XCTAssert(FiveFactorial.reverse() == reversed)
        
        let transposed = [0, 60, 20, 80, 40, 100, 5, 65, 25, 85, 45, 105, 10, 70, 30, 90, 50, 110, 15, 75, 35, 95, 55, 115, 1, 61, 21, 81, 41, 101, 6, 66, 26, 86, 46, 106, 11, 71, 31, 91, 51, 111, 16, 76, 36, 96, 56, 116, 2, 62, 22, 82, 42, 102, 7, 67, 27, 87, 47, 107, 12, 72, 32, 92, 52, 112, 17, 77, 37, 97, 57, 117, 3, 63, 23, 83, 43, 103, 8, 68, 28, 88, 48, 108, 13, 73, 33, 93, 53, 113, 18, 78, 38, 98, 58, 118, 4, 64, 24, 84, 44, 104, 9, 69, 29, 89, 49, 109, 14, 74, 34, 94, 54, 114, 19, 79, 39, 99, 59, 119].reshape([5, 4, 3, 2])
        
        XCTAssert(FiveFactorial.transpose() == transposed)

        XCTAssert(FiveFactorial.rotate(0) == FiveFactorial)
        XCTAssert(FiveFactorial.rotate(5) == FiveFactorial)
        XCTAssert(FiveFactorial.rotate(-5) == FiveFactorial)
        
        let rot1 = [1, 2, 3, 4, 0, 6, 7, 8, 9, 5, 11, 12, 13, 14, 10, 16, 17, 18, 19, 15, 21, 22, 23, 24, 20, 26, 27, 28, 29, 25, 31, 32, 33, 34, 30, 36, 37, 38, 39, 35, 41, 42, 43, 44, 40, 46, 47, 48, 49, 45, 51, 52, 53, 54, 50, 56, 57, 58, 59, 55, 61, 62, 63, 64, 60, 66, 67, 68, 69, 65, 71, 72, 73, 74, 70, 76, 77, 78, 79, 75, 81, 82, 83, 84, 80, 86, 87, 88, 89, 85, 91, 92, 93, 94, 90, 96, 97, 98, 99, 95, 101, 102, 103, 104, 100, 106, 107, 108, 109, 105, 111, 112, 113, 114, 110, 116, 117, 118, 119, 115].reshape([2, 3, 4, 5])
        
        XCTAssert(FiveFactorial.rotate(1) == rot1)
        XCTAssert(FiveFactorial.rotate(-4) == rot1)
        
        let rot2 = [2, 3, 4, 0, 1, 7, 8, 9, 5, 6, 12, 13, 14, 10, 11, 17, 18, 19, 15, 16, 22, 23, 24, 20, 21, 27, 28, 29, 25, 26, 32, 33, 34, 30, 31, 37, 38, 39, 35, 36, 42, 43, 44, 40, 41, 47, 48, 49, 45, 46, 52, 53, 54, 50, 51, 57, 58, 59, 55, 56, 62, 63, 64, 60, 61, 67, 68, 69, 65, 66, 72, 73, 74, 70, 71, 77, 78, 79, 75, 76, 82, 83, 84, 80, 81, 87, 88, 89, 85, 86, 92, 93, 94, 90, 91, 97, 98, 99, 95, 96, 102, 103, 104, 100, 101, 107, 108, 109, 105, 106, 112, 113, 114, 110, 111, 117, 118, 119, 115, 116].reshape([2, 3, 4, 5])

        XCTAssert(FiveFactorial.rotate(2) == rot2)
        XCTAssert(FiveFactorial.rotate(-3) == rot2)
        
        let rot3 = [3, 4, 0, 1, 2, 8, 9, 5, 6, 7, 13, 14, 10, 11, 12, 18, 19, 15, 16, 17, 23, 24, 20, 21, 22, 28, 29, 25, 26, 27, 33, 34, 30, 31, 32, 38, 39, 35, 36, 37, 43, 44, 40, 41, 42, 48, 49, 45, 46, 47, 53, 54, 50, 51, 52, 58, 59, 55, 56, 57, 63, 64, 60, 61, 62, 68, 69, 65, 66, 67, 73, 74, 70, 71, 72, 78, 79, 75, 76, 77, 83, 84, 80, 81, 82, 88, 89, 85, 86, 87, 93, 94, 90, 91, 92, 98, 99, 95, 96, 97, 103, 104, 100, 101, 102, 108, 109, 105, 106, 107, 113, 114, 110, 111, 112, 118, 119, 115, 116, 117].reshape([2, 3, 4, 5])
        
        XCTAssert(FiveFactorial.rotate(3) == rot3)
        XCTAssert(FiveFactorial.rotate(-2) == rot3)
        
        let rot4 = [4, 0, 1, 2, 3, 9, 5, 6, 7, 8, 14, 10, 11, 12, 13, 19, 15, 16, 17, 18, 24, 20, 21, 22, 23, 29, 25, 26, 27, 28, 34, 30, 31, 32, 33, 39, 35, 36, 37, 38, 44, 40, 41, 42, 43, 49, 45, 46, 47, 48, 54, 50, 51, 52, 53, 59, 55, 56, 57, 58, 64, 60, 61, 62, 63, 69, 65, 66, 67, 68, 74, 70, 71, 72, 73, 79, 75, 76, 77, 78, 84, 80, 81, 82, 83, 89, 85, 86, 87, 88, 94, 90, 91, 92, 93, 99, 95, 96, 97, 98, 104, 100, 101, 102, 103, 109, 105, 106, 107, 108, 114, 110, 111, 112, 113, 119, 115, 116, 117, 118].reshape([2, 3, 4, 5])
        
        XCTAssert(FiveFactorial.rotate(4) == rot4)
        XCTAssert(FiveFactorial.rotate(-1) == rot4)
        
        //
        
        XCTAssert(FiveFactorial.rotateFirst(0) == FiveFactorial)
        XCTAssert(FiveFactorial.rotateFirst(-2) == FiveFactorial)
        XCTAssert(FiveFactorial.rotateFirst(2) == FiveFactorial)
        
        
        let rotf1 = [60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59].reshape([2, 3, 4, 5])
        
        XCTAssert(FiveFactorial.rotateFirst(1) == rotf1)
        XCTAssert(FiveFactorial.rotateFirst(-1) == rotf1)
        XCTAssert(FiveFactorial.rotateFirst(3) == rotf1)
        XCTAssert(FiveFactorial.rotateFirst(-3) == rotf1)

    }

//    func testAppendConcat() {
//        XCTAssert(false)
//    }
//    
//    func testMaps() {
//        XCTAssert(false)
//    }
//    
//    func testEnumerate() {
//        XCTAssert(false)
//    }
//    
//    func testReduceScan() {
//        XCTAssert(false)
//    }
//    
//    func testOuterInner() {
//        XCTAssert(false)
//    }
}
