// Copyright 2016 The Shear Authors. All rights reserved.
// Use of this source code is governed by a MIT-style
// license that can be found in the LICENSE file.

import XCTest
import Shear

class OpertaionsTests: XCTestCase {

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
    
    func testSequence() {
        let correctValues: [(Shear.Tensor<Int>, Shear.Tensor<Int>)] = [
            ([0].ravel(), [7].ravel()),
            ([0, 1, 2, 3].ravel(), [3, 7, 11, 15].ravel()),
            (iota(9).reshape([3, 3]), [2, 5, 8, 11, 14, 17, 20, 23, 26].reshape([3, 3])),
            ([0].ravel(), [6].ravel()),
            ([1].ravel(), [7].ravel()),
            (iota(60).reshape([3, 4, 5]), [4, 9, 14, 19, 24, 29, 34, 39, 44, 49, 54, 59, 64, 69, 74, 79, 84, 89, 94, 99, 104, 109, 114, 119].reshape([2, 3, 4])),
            ([0].ravel(), [0].ravel()),
        ]
        
        zip(allTensors, correctValues).forEach {
            XCTAssert($0.0.sequenceFirst.first! == $0.1.0)
            XCTAssert($0.0.sequenceLast.last! == $0.1.1)
        }
        
    }
    
    func testReshape() {
        let testVectors: [([Int], Shear.Tensor<Int>)] = [
            ([2, 4], Tensor(shape: [2, 4], tensor: iota(8))),
            ([16], iota(16)),
            ([1, 3, 1, 1, 1, 9, 1], Tensor(shape: [3, 9], tensor: iota(27))),
            ([2, 2], Tensor(shape: [2, 2], values: [0, 2, 4, 6])),
            ([1, 4], Tensor(shape: [4, 1], values: [1, 3, 5, 7])),
        ]
        
        zip(allTensors, testVectors).forEach {
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
        
        zip(allTensors, correctValues).forEach {
            XCTAssert($0.0.ravel() == $0.1)
        }
    }
    
    func testEnclose() {
        // We're only testing the shape is as expected, this does not guarantee the method is actually working, 
        // but it should detect most types of breaking changes to the existing implimentation.
        allTensors.dropLast().forEach { // we drop the last as enclosing scalar won't be fun.
            // Empty enclose
            let enclosedTensor = $0.enclose([])
            XCTAssert(enclosedTensor.scalar! == $0)
            
            // Enclose with axis
            let encloseFirst = $0.enclose(0)
            XCTAssert(encloseFirst.shape == [Int]($0.shape.dropFirst()))
            XCTAssert(encloseFirst[linear: 0].shape == [$0.shape.first!])
            
            let encloseLast = $0.enclose($0.rank - 1)
            XCTAssert(encloseLast.shape == [Int]($0.shape.dropLast()))
            XCTAssert(encloseLast[linear: 0].shape == [$0.shape.last!])
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

    func testAppendConcatLaminateInterpose() {
        let vEvenOdd = [0, 2, 4, 6, 1, 3, 5, 7, 9999].ravel()
        XCTAssert(vEvens.append(vOdds).append(9999) == vEvenOdd)
        XCTAssert(vEvens.concat(vOdds).concat(9999) == vEvenOdd)
        
        let iotaRect = iota(9).reshape([3, 3])
        XCTAssert(iotaCube.append(iotaRect) == [0, 1, 2, 0, 3, 4, 5, 1, 6, 7, 8, 2, 9, 10, 11, 3, 12, 13, 14, 4, 15, 16, 17, 5, 18, 19, 20, 6, 21, 22, 23, 7, 24, 25, 26, 8].reshape([3, 3, 4]))
        XCTAssert(iotaCube.concat(iotaRect) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 0, 1, 2, 3, 4, 5, 6, 7, 8].reshape([4, 3, 3]))
        
        let conIotaRect = iotaRect.laminate(iotaRect).concat(iotaRect)
        XCTAssert(iotaCube.laminate(conIotaRect) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 0, 1, 2, 3, 4, 5, 6, 7, 8, 0, 1, 2, 3, 4, 5, 6, 7, 8, 0, 1, 2, 3, 4, 5, 6, 7, 8].reshape([2, 3, 3, 3]))
        XCTAssert(iotaCube.interpose(conIotaRect) == [0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 0, 10, 1, 11, 2, 12, 3, 13, 4, 14, 5, 15, 6, 16, 7, 17, 8, 18, 0, 19, 1, 20, 2, 21, 3, 22, 4, 23, 5, 24, 6, 25, 7, 26, 8].reshape([3, 3, 3, 2]))
    }

    func testMaps() {
        // If any of these ever broke, most other tests would fail.
        XCTAssert(vEvens.map { $0 + 1 } == vOdds)
        XCTAssert(FiveFactorial.map { 0 - $0 } == (iota(120) * -1).reshape([2, 3, 4, 5]))
        
        XCTAssert(FiveFactorial.vectorMap(byRows: true, transform: { $0.rotate(3) }) == [3, 4, 0, 1, 2, 8, 9, 5, 6, 7, 13, 14, 10, 11, 12, 18, 19, 15, 16, 17, 23, 24, 20, 21, 22, 28, 29, 25, 26, 27, 33, 34, 30, 31, 32, 38, 39, 35, 36, 37, 43, 44, 40, 41, 42, 48, 49, 45, 46, 47, 53, 54, 50, 51, 52, 58, 59, 55, 56, 57, 63, 64, 60, 61, 62, 68, 69, 65, 66, 67, 73, 74, 70, 71, 72, 78, 79, 75, 76, 77, 83, 84, 80, 81, 82, 88, 89, 85, 86, 87, 93, 94, 90, 91, 92, 98, 99, 95, 96, 97, 103, 104, 100, 101, 102, 108, 109, 105, 106, 107, 113, 114, 110, 111, 112, 118, 119, 115, 116, 117].reshape([2, 3, 4, 5]))
        XCTAssert(FiveFactorial.vectorMap(byRows: false, transform: { $0.rotate(1) }) == [60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59].reshape([2, 3, 4, 5]))
        
        XCTAssert(zip(iotaCube, iotaCube).map(+) == iotaCube.map { $0 * 2 })
        
    }

    func testCoordinate() {
        for (i, v) in iota(50).coordinate() {
            XCTAssert(i == [v])
        }
        
        let stride = FiveFactorial.shape.reversed().scan(1, combine: *).dropLast().reversed()
        FiveFactorial.coordinate().forEach { (i, v) in
            let dot = zip(i, stride).map(*).reduce(+)
            XCTAssert(dot == v)
            XCTAssert(FiveFactorial[i] == v)
        }
    }

    func testReduceScan() {
        var results = [Tensor<Int>]()
        results.append([0, 0, 0, 0, 0, 5, 30, 210, 1680, 15120, 10, 110, 1320, 17160, 240240, 15, 240, 4080, 73440, 1395360, 20, 420, 9240, 212520, 5100480, 25, 650, 17550, 491400, 14250600, 30, 930, 29760, 982080, 33390720, 35, 1260, 46620, 1771560, 69090840, 40, 1640, 68880, 2961840, 130320960, 45, 2070, 97290, 4669920, 228826080, 50, 2550, 132600, 7027800, 379501200, 55, 3080, 175560, 10182480, 600766320, 60, 3660, 226920, 14295960, 914941440, 65, 4290, 287430, 19545240, 1348621560, 70, 4970, 357840, 26122320, 1933051680, 75, 5700, 438900, 34234200, 2704501800, 80, 6480, 531360, 44102880, 3704641920, 85, 7310, 635970, 55965360, 4980917040, 90, 8190, 753480, 70073640, 6586922160, 95, 9120, 884640, 86694720, 8582777280, 100, 10100, 1030200, 106110600, 11035502400, 105, 11130, 1190910, 128618280, 14019392520, 110, 12210, 1367520, 154529760, 17616392640, 115, 13340, 1560780, 184172040, 21916472760].reshape([2, 3, 4, 5]))
        results.append([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 0, 61, 124, 189, 256, 325, 396, 469, 544, 621, 700, 781, 864, 949, 1036, 1125, 1216, 1309, 1404, 1501, 1600, 1701, 1804, 1909, 2016, 2125, 2236, 2349, 2464, 2581, 2700, 2821, 2944, 3069, 3196, 3325, 3456, 3589, 3724, 3861, 4000, 4141, 4284, 4429, 4576, 4725, 4876, 5029, 5184, 5341, 5500, 5661, 5824, 5989, 6156, 6325, 6496, 6669, 6844, 7021].reshape([2, 3, 4, 5]))
        results.append([7, 7, 8, 10, 13, 17, 7, 12, 18, 25, 33, 42, 7, 17, 28, 40, 53, 67, 7, 22, 38, 55, 73, 92, 7, 27, 48, 70, 93, 117, 7, 32, 58, 85, 113, 142, 7, 37, 68, 100, 133, 167, 7, 42, 78, 115, 153, 192, 7, 47, 88, 130, 173, 217, 7, 52, 98, 145, 193, 242, 7, 57, 108, 160, 213, 267, 7, 62, 118, 175, 233, 292, 7, 67, 128, 190, 253, 317, 7, 72, 138, 205, 273, 342, 7, 77, 148, 220, 293, 367, 7, 82, 158, 235, 313, 392, 7, 87, 168, 250, 333, 417, 7, 92, 178, 265, 353, 442, 7, 97, 188, 280, 373, 467, 7, 102, 198, 295, 393, 492, 7, 107, 208, 310, 413, 517, 7, 112, 218, 325, 433, 542, 7, 117, 228, 340, 453, 567, 7, 122, 238, 355, 473, 592].reshape([2, 3, 4, 6]))
        results.append([7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 69, 71, 73, 75, 77, 79, 81, 83, 85, 87, 89, 91, 93, 95, 97, 99, 101, 103, 105, 107, 109, 111, 113, 115, 117, 119, 121, 123, 125, 127, 129, 131, 133, 135, 137, 139, 141, 143, 145, 147, 149, 151, 153, 155, 157, 159, 161, 163, 165, 167, 169, 171, 173, 175, 177, 179, 181, 183, 185].reshape([3, 3, 4, 5]))
        results.append([0, 15120, 240240, 1395360, 5100480, 14250600, 33390720, 69090840, 130320960, 228826080, 379501200, 600766320, 914941440, 1348621560, 1933051680, 2704501800, 3704641920, 4980917040, 6586922160, 8582777280, 11035502400, 14019392520, 17616392640, 21916472760].reshape([2, 3, 4]))
        results.append([0, 61, 124, 189, 256, 325, 396, 469, 544, 621, 700, 781, 864, 949, 1036, 1125, 1216, 1309, 1404, 1501, 1600, 1701, 1804, 1909, 2016, 2125, 2236, 2349, 2464, 2581, 2700, 2821, 2944, 3069, 3196, 3325, 3456, 3589, 3724, 3861, 4000, 4141, 4284, 4429, 4576, 4725, 4876, 5029, 5184, 5341, 5500, 5661, 5824, 5989, 6156, 6325, 6496, 6669, 6844, 7021].reshape([3, 4, 5]))
        results.append([17, 42, 67, 92, 117, 142, 167, 192, 217, 242, 267, 292, 317, 342, 367, 392, 417, 442, 467, 492, 517, 542, 567, 592].reshape([2, 3, 4]))
        results.append([67, 69, 71, 73, 75, 77, 79, 81, 83, 85, 87, 89, 91, 93, 95, 97, 99, 101, 103, 105, 107, 109, 111, 113, 115, 117, 119, 121, 123, 125, 127, 129, 131, 133, 135, 137, 139, 141, 143, 145, 147, 149, 151, 153, 155, 157, 159, 161, 163, 165, 167, 169, 171, 173, 175, 177, 179, 181, 183, 185].reshape([3, 4, 5]))
        
        XCTAssert(FiveFactorial.scan(*) == results[0])
        XCTAssert(FiveFactorial.scanFirst(*) == results[1])
        XCTAssert(FiveFactorial.scan(7, combine: +) == results[2])
        XCTAssert(FiveFactorial.scanFirst(7, combine: +) == results[3])
        
        XCTAssert(FiveFactorial.reduce(*) == results[4])
        XCTAssert(FiveFactorial.reduceFirst(*) == results[5])
        XCTAssert(FiveFactorial.reduce(7, combine: +) == results[6])
        XCTAssert(FiveFactorial.reduceFirst(7, combine: +) == results[7])
    }

    func testOuterInner() {
        let op = outer(vEvens, vOdds).map(*)
        XCTAssert(op == [
            0,  0,  0,  0,
            2,  6, 10, 14,
            4, 12, 20, 28,
            6, 18, 30, 42
            ].reshape([4, 4]))
        
        XCTAssert(inner(vEvens, vOdds, product: *, sum: +).scalar! == 68)
        let swiftTypeInferenceIsSlow = inner(vEvens, vOdds, product: *, sum: +, initialSum: 5)
        XCTAssert(swiftTypeInferenceIsSlow.scalar! == 68 + 5)
        
        let a = iota(12).reshape([4, 3])
        let b = iota(6).reshape([3, 2])
        let c = a ∙ b
        XCTAssert(c == [10, 13, 28, 40, 46, 67, 64, 94].reshape([4, 2]))
    }
}
