import Foundation

struct GridPosition: Hashable, Sendable, Identifiable {
    let row: Int
    let col: Int

    var id: String { "\(row),\(col)" }

    func isAdjacent(to other: GridPosition) -> Bool {
        guard self != other else { return false }
        return abs(row - other.row) <= 1 && abs(col - other.col) <= 1
    }
}
