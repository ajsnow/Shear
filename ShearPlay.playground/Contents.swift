//: Playground - noun: a place where people can play

import Cocoa
import Shear

var str = "Hello, playground"

let a = DenseArray(shape: [5, 5, 5], repeatedValue: 0)
a

//print(a)

let b = DenseArray(shape: [4, 3], baseArray: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])

print(b)

let c = DenseArray(shape: [2, 3], baseArray: [0, 1, 2, 3, 4, 5])

print(c)

c[1, 2]

