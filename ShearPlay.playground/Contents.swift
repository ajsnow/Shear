//: Playground - noun: a place where people can play

import Cocoa
import Shear



var str = "Hello, playground"

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
big.isRowVector
big.isColumnVector
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
let matB = DenseArray(shape: [2, 3], baseArray: [9, 10, 11, 12, 13, 14])

//innerProduct(matA, matB) // should be [[62, 80], [152, 197]]

let matC = DenseArray(shape: [2, 3], baseArray: [9, 10, 11, 12, 13, 14])

//innerProduct(matA, matC) // should be error

vecB.reduce(1, combine: *).scalar!

let iotaCube = DenseArray(shape: [2, 2, 2], baseArray: [0, 1, 2, 3, 4, 5, 6, 7])
iotaCube.reduce(0, combine: +)

let iotaSq = DenseArray(shape: [2, 2], baseArray: [0, 1, 2, 3])

iotaSq * iotaSq

inner(iotaSq, iotaSq, product: *, sum: +)

inner(vecA, vecB, product: *, sum: +)

print(inner(iotaCube, iotaCube, product: *, sum: +))

vecA ∙ vecB
matA ∙ matB

let me = Mirror(reflecting: [1, 2, 3, 4])
let thou = Mirror(reflecting: 5)

me.children.first!
thou.children.count
thou.subjectType

//extension Shear.DenseArray {
//    
//    init<Z>(array: [Z]) {
//        if Z is CollectionType {
//            
//        }
//        
//    }
//
//}
//asdf(matA)

//arraySum2(matA, matB)
//
//let _A = iotaCube.enclose(0)
//let _B = iotaCube.enclose(iotaCube.shape.count - 1)
//
//print(outer(_A, rhs: _B, transform: +).reduce(1, combine: *))
//
//
//let oa = DenseArray(shape: [2, 2], baseArray: ["a", "b", "c", "d"])
//let ob = DenseArray(shape: [2, 2], baseArray: ["e", "f", "g", "h"])
//print(outer(oa, rhs: ob, transform: +))
//
//print(outer(iotaCube, rhs: iotaCube, transform: *))
//
//
//print(iotaCube.sequenceLast)
//print(iotaCube.sequenceFirst)
//print(iotaCube.sequence(0))
//print(iotaCube.sequence(1))
//print(iotaCube.sequence(2))
//
//let superCube = DenseArray(shape: [2, 2, 2], baseArray: [0, 4, 1, 5, 2, 6, 3, 7])
//print("Lol: \(superCube)")
//print(superCube.sequence(0))
//
//
let threesCube = DenseArray(shape: [3, 3, 3], baseArray: Swift.Array(0...26))
print("\n\n\n\n", inner(threesCube, threesCube, product: *, sum: +))


let jj = DenseArray(shape: [2, 3], baseArray: [0, 1, 2, 3, 4, 5])
jj.reduce(+)
jj.scan(+)


