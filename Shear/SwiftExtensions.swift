// Copyright 2016 The Shear Authors. All rights reserved.
// Use of this source code is governed by a MIT-style
// license that can be found in the LICENSE file.

import Foundation

public extension Sequence {
    
    /// Return the array of partial results of repeatedly calling `combine` with an
    /// accumulated value initialized to `initial` and each element of
    /// `self`, in turn, i.e. return
    /// `[initial, combine(results[0], self[0]),...combine(results[count-1], self[count-1]]`.
    func scan<T>(_ initial: T, combine: (T, Self.Iterator.Element) -> T) -> [T] {
        var results: [T] = [initial]
        for (i, v) in self.enumerated() {
            results.append(combine(results[i], v))
        }
        return results
    }
    
}

// We could have defined these on sequence types, but this definition is much nicer
public extension Collection where SubSequence.Iterator.Element == Iterator.Element {
    
    func reduce(_ combine: (Iterator.Element, Iterator.Element) -> Iterator.Element) -> Iterator.Element {
        guard !isEmpty else { fatalError("CollectionType must have at least one element to be self-reduced") }
        
        return dropFirst().reduce(first!, combine)
    }

    /// Return the array of partial results of repeatedly calling `combine` with an
    /// accumulated value initialized to `initial` and each element of
    /// `self`, in turn, i.e. return
    /// `[self[0], combine(results[0], self[1]),...combine(results[count-2], self[count-1]]`.
    func scan(_ combine: (Iterator.Element, Iterator.Element) -> Iterator.Element) -> [Iterator.Element] {
        guard !isEmpty else { fatalError("CollectionType must have at least one element to be self-scanned.") }
        
        var results = [first!] as [Iterator.Element]
        for v in self.dropFirst() {
            results.append(combine(results.last!, v))
        }
        return results
    }
    
}

extension Collection where Iterator.Element: Equatable {
    
    func allEqual() -> Bool {
        guard let first = self.first else { return true } // An empty array certainly has uniform contents.
        return !self.contains { $0 != first }
    }
    
}

extension Collection {
    
    func allEqual<A>(_ compare: (Iterator.Element) -> A) -> Bool where A: Equatable {
        guard let first = self.first else { return true } // An empty array certainly has uniform contents.
        let firstTransformed = compare(first)
        return !self.contains { compare($0) != firstTransformed }
    }
    
}

public extension Array {
    
    public func ravel() -> Tensor<Iterator.Element> {
        return Tensor(shape: [Int(count)], values: self)
    }
    
    public func reshape(_ shape: [Int]) -> Tensor<Iterator.Element> {
        return Tensor(shape: shape, values: self)
    }
    
    public func rotate(_ s: Int) -> [Iterator.Element] {
        let shift = modulo(s, base: count)
        let back = self[0..<shift]
        let front = self[shift..<count]
        return [Element](front) + back
    }
    
}

extension Collection where Index: Integer {

    func ravel() -> Tensor<Iterator.Element> {
        let array = self.map { $0 }
        return array.ravel()
    }
    
    func reshape(_ shape: [Int]) -> Tensor<Iterator.Element> {
        return Tensor(shape: shape, values: Array(self))
    }
    
}

extension String {
    
    func leftpad(_ count: Int, padding: Character = " ") -> String {
        let paddingCount = count - self.characters.count
        
        switch paddingCount {
        case 0:
            return self
        case _ where paddingCount < 0:
            return self[self.startIndex..<self.characters.index(self.startIndex, offsetBy: count)]
        default:
            let pad = String(repeating: String(padding), count: paddingCount)
            return pad + self
        }
    }
    
}

func modulo(_ count: Int, base: Int) -> Int {
    let m = count % base
    return m < 0 ? m + base : m
}

