import Foundation

extension Array {

    func at(index: Int) -> Element? {
        guard self.count > index else {
            return nil
        }
        return self[index]
    }

    func chunks(_ chunkSize: Int) -> [[Element]] {
        stride(from: 0, to: self.count, by: chunkSize).map {
            Array(self[$0..<Swift.min($0 + chunkSize, self.count)])
        }
    }

}

extension Array where Element: Equatable {

    func removeDuplicates() -> Self {
        var uniqueElements = [Element]()
        for element in self {
            if !uniqueElements.contains(element) {
                uniqueElements.append(element)
            }
        }
        return uniqueElements
    }

}
