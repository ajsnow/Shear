//
//  Products.swift
//  Shear
//
//  Created by Andrew Snow on 7/12/15.
//  Copyright © 2015 Andrew Snow. All rights reserved.
//

import Foundation
import Accelerate

// MARK: - Declare operators

infix operator ⊗ {} /// Tensor (Outer) Product Operator
infix operator × {} /// Cross Product Operator
infix operator ∙ {} /// Dot (Inner) Product Operator
//infix operator * {} /// Element-wise Product Operator

// MARK: - Real Functions

private func elementwiseArrayProduct<A: Array, B: Array where A.Element == B.Element, A.Element: NumericType>
    (lhs: A, _ rhs: B) -> DenseArray<A.Element> {
        precondition(lhs.shape == rhs.shape, "Arrays must have same shape to be elementwise added")
        return DenseArray(shape: lhs.shape, baseArray: zip(lhs.allElements, rhs.allElements).map(*))
}

private func elementwiseScalarProduct<A: Array, Scalar: NumericType where A.Element == Scalar>
    (a: A, scalar: Scalar) -> DenseArray<A.Element> {
        let multiplyScalar = { $0 * scalar}
        return DenseArray(shape: a.shape, baseArray: a.allElements.map(multiplyScalar))
}

private func innerProduct<A: Array, B: Array where A.Element == B.Element, A.Element: NumericType>
    (left: A, _ right: B) -> DenseArray<A.Element> {
        return inner(left, right: right, transform: *, initial: 0, combine: +)
}

public func outer<T, Z, A: Array, B: Array where A.Element == T, B.Element == T>
    (left: A, _ right: B, _ transform: ((T, T) -> Z)) -> DenseArray<Z> {
        var baseArray = Swift.Array<Z>()
        baseArray.reserveCapacity(Int(left.allElements.count * right.allElements.count))
        
        for l in left.allElements {
            for r in right.allElements {
                baseArray.append(transform(l, r))
            }
        }
        
        return DenseArray(shape: left.shape + right.shape, baseArray: baseArray)
}

public func inner<T, Y, Z, A: Array, B: Array where A.Element == T, B.Element == T>
    (left: A, right: B, transform: ((ArraySlice<T>, ArraySlice<T>) -> DenseArray<Y>), initial: Z, combine: ((Z, Y) -> Z)) -> DenseArray<Z> {
        
        let cA = left.enclose(left.shape.count - 1)
        let cB = right.enclose(0)
        
        let op = outer(cA, cB, transform)
        let baseArray = op.allElements.map{ $0.reduce(initial, combine: combine).allElements.map {$0} }.flatMap {$0}
        return DenseArray(shape: op.shape, baseArray: baseArray)
        
        
//        if left.isVector && right.isVector {
//            return transform(ArraySlice(baseArray: left), ArraySlice(baseArray: right)).reduce(initial, combine: combine)
//        }
//        
//        let sliceA = left.sequenceFirst
//        let sliceB = right.sequenceLast
//        let aosA = DenseArray(shape: [sliceA.count], baseArray: sliceA)
//        let aosB = DenseArray(shape: [sliceB.count], baseArray: sliceB)
//        let aoaosAB = outer(aosA, rhs: aosB, transform: transform)
//        return DenseArray(collection: aoaosAB.allElements.map { $0.reduce(initial, combine: combine)})
        ////        let unshaped = DenseArray(collection: aoaosAB.allElements.map { $0.reduce(initial, combine: combine)})
        ////        return DenseArray(shape: aoaosAB.shape, baseArray: unshaped)
}

public extension Array {
    public func enclose(axes: Int...) -> DenseArray<ArraySlice<Element>> {
        // Since this algo is recursive, we only check and operate on the head of the list.
        guard let axis = axes.first else { fatalError("ran out of axes") }
        guard axis < shape.count else { fatalError("domain") }
        
        let newShape = Swift.Array(shape.enumerate().lazy.filter { $0.index != axis }.map { $0.element })
        
        let internalIndicesList = makeRowMajorIndexGenerator(newShape).map { newIndices -> [ArrayIndex] in
            var internalIndices = newIndices.map { ArrayIndex.SingleValue($0) }
            internalIndices.insert(.All, atIndex: axis)
            return internalIndices
        }
        
        let subarrays = internalIndicesList.map { self[$0] }
    
        return DenseArray(shape: newShape, baseArray: subarrays)
    }
    
    
    func reduce<Z>(initial: Z, combine: ((Z, Element)-> Z)) -> DenseArray<Z> {
        if let s = scalar {
            return DenseArray(shape: [], baseArray: [combine(initial, s)])
        }
        
        let slice = sequenceLast
        guard slice.first?.scalar != nil else {
            return DenseArray(collection: DenseArray(collection: slice.map { $0.reduce(initial, combine: combine) }).sequenceLast)
        }
        
        let result = slice.map { $0.scalar! }.reduce(initial, combine: combine)
        return DenseArray(shape: [], baseArray: [result])
    }
}


//private func outer<T, Z, A: SequenceType, B: SequenceType where A.Generator.Element == T, B.Generator.Element == T>
//    (map: ((T, T)) -> Z, lhs: A, rhs: B) -> [[Z]] {
//        return lhs.map { a -> [Z] in
//            rhs.map {
//                b -> Z in
//                map((a, b))
//            }
//        }
//}

// MARK: - Operators

public func *<A: Array, B: Array where A.Element == B.Element, A.Element: NumericType>
    (lhs: A, rhs: B) -> DenseArray<A.Element> {
        return elementwiseArrayProduct(lhs, rhs)
}

public func ∙<A: Array, B: Array where A.Element == B.Element, A.Element: NumericType>
    (lhs: A, rhs: B) -> DenseArray<A.Element> {
        return innerProduct(lhs, rhs)
}