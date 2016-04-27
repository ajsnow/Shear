// Copyright 2016 The Shear Authors. All rights reserved.
// Use of this source code is governed by a MIT-style
// license that can be found in the LICENSE file.

import Foundation

extension SequenceType {
    
    /// Return the array of partial results of repeatedly calling `combine` with an
    /// accumulated value initialized to `initial` and each element of
    /// `self`, in turn, i.e. return
    /// `[initial, combine(results[0], self[0]),...combine(results[count-1], self[count-1]]`.
    func scan<T>(initial: T, @noescape combine: (T, Self.Generator.Element) -> T) -> [T] {
        var results: Swift.Array<T> = [initial]
        for (i, v) in self.enumerate() {
            results.append(combine(results[i], v))
        }
        return results
    }
    
}

// We could have defined these on sequence types, but this definition is much nicer
extension CollectionType where SubSequence.Generator.Element == Generator.Element {
    
    func reduce(@noescape combine: (Generator.Element, Generator.Element) -> Generator.Element) -> Generator.Element {
        guard !isEmpty else { fatalError("CollectionType must have at least one element to be self-reduced") }
        
        return dropFirst().reduce(first!, combine: combine)
    }

    /// Return the array of partial results of repeatedly calling `combine` with an
    /// accumulated value initialized to `initial` and each element of
    /// `self`, in turn, i.e. return
    /// `[self[0], combine(results[0], self[1]),...combine(results[count-2], self[count-1]]`.
    func scan(@noescape combine: (Generator.Element, Generator.Element) -> Generator.Element) -> [Generator.Element] {
        guard !isEmpty else { fatalError("CollectionType must have at least one element to be self-scanned.") }
        
        var results = [first!] as [Generator.Element]
        for v in self.dropFirst() {
            results.append(combine(results.last!, v))
        }
        return results
    }
    
}

public extension Swift.Array {
    
    public func ravel() -> DenseArray<Generator.Element> {
        return DenseArray(shape: [Int(count)], baseArray: self)
    }
    
    public func reshape(shape: [Int]) -> DenseArray<Generator.Element> {
        return DenseArray(shape: shape, baseArray: self)
    }
    
    public func rotate(s: Int) -> [Generator.Element] {
        let shift = modulo(s, base: count)
        let back = self[0..<shift]
        let front = self[shift..<count]
        return [Element](front) + back
    }
    
}

extension CollectionType where Index.Distance: NumericType {
    
    func ravel() -> DenseArray<Generator.Element> {
        let array = self.map { $0 }
        return array.ravel()
    }
    
    func reshape(shape: [Int]) -> DenseArray<Generator.Element> {
        return DenseArray(shape: shape, baseArray: self.map { $0 } )
    }
    
}

extension String {
    
    func leftpad(count: Int, padding: Character = " ") -> String {
        let paddingCount = count - self.characters.count
        
        switch paddingCount {
        case 0:
            return self
        case _ where paddingCount < 0:
            return self[self.startIndex..<self.startIndex.advancedBy(count)]
        default:
            let pad = String(count: paddingCount, repeatedValue: padding)
            return pad + self
        }
    }
    
}

func modulo(count: Int, base: Int) -> Int {
    let m = count % base
    return m < 0 ? m + base : m
}

