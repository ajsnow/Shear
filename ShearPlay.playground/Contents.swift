//: Playground - noun: a place where people can play

import Cocoa
import Shear

var str = "Hello, playground"

let a = DenseArray(shape: [1, 2, 3, 4, 5], repeatedValue: 0).allElements.count

//print(a)

let b = DenseArray(shape: [4, 3], baseArray: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])

//print(b)

let c = DenseArray(shape: [2, 3], baseArray: [0, 1, 2, 3, 4, 5])

print(c)

c[1, 2]

        let d = c[nil, [0, 2]]
//let d = ArraySlice(baseArray: c, viewIndices: [nil, [0, 2]])

print(d)

let e = c[$, Shear.$]
let f = c[nil, 1]

let big = DenseArray(shape: [1, 2, 3, 4, 5], baseArray: Array(0..<120))

big.shape
big.shape.count
big.rank
big.isEmpty
big.isScalar
big.isVector
big.isRowVector
big.isColumnVector
big.scalarValue

//let smallish = ArraySlice(baseArray: big, viewIndices: [ArrayIndex.All, .SingleValue(0), .Range(0, 2), .List([0, 2, 3]), .All])
//let small = ArraySlice(baseArray: smallish, viewIndices: [.SingleValue(0), .Range(0, 2), .List([1, 2])])
