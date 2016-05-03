// Copyright 2016 The Shear Authors. All rights reserved.
// Use of this source code is governed by a MIT-style
// license that can be found in the LICENSE file.

import Foundation

public extension SequenceType {
    
    /// Return the array of partial results of repeatedly calling `combine` with an
    /// accumulated value initialized to `initial` and each element of
    /// `self`, in turn, i.e. return
    /// `[initial, combine(results[0], self[0]),...combine(results[count-1], self[count-1]]`.
    func scan<T>(initial: T, @noescape combine: (T, Self.Generator.Element) -> T) -> [T] {
        var results: [T] = [initial]
        for (i, v) in self.enumerate() {
            results.append(combine(results[i], v))
        }
        return results
    }
    
}

// We could have defined these on sequence types, but this definition is much nicer
public extension CollectionType where SubSequence.Generator.Element == Generator.Element {
    
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

extension CollectionType where Generator.Element: Equatable {
    
    func allEqual() -> Bool {
        guard let first = self.first else { return true } // An empty array certainly has uniform contents.
        return !self.contains { $0 != first }
    }
    
}

extension CollectionType {
    
    func allEqual<A where A: Equatable>(compare: Generator.Element -> A) -> Bool {
        guard let first = self.first else { return true } // An empty array certainly has uniform contents.
        let firstTransformed = compare(first)
        return !self.contains { compare($0) != firstTransformed }
    }
    
}

public extension Swift.Array {
    
    public func ravel() -> ComputedArray<Generator.Element> {
        return ComputedArray(DenseArray(shape: [Int(count)], baseArray: self))
    }
    
    public func reshape(shape: [Int]) -> ComputedArray<Generator.Element> {
        return ComputedArray(DenseArray(shape: shape, baseArray: self))
    }
    
    public func rotate(s: Int) -> [Generator.Element] {
        let shift = modulo(s, base: count)
        let back = self[0..<shift]
        let front = self[shift..<count]
        return [Element](front) + back
    }
    
}

extension CollectionType where Index.Distance: NumericType {
    
    func ravel() -> ComputedArray<Generator.Element> {
        let array = self.map { $0 }
        return array.ravel()
    }
    
    func reshape(shape: [Int]) -> ComputedArray<Generator.Element> {
        return ComputedArray(DenseArray(shape: shape, baseArray: self.map { $0 } ))
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

