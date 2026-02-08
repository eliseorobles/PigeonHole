import Foundation

enum CellState: Hashable, Sendable {
    case empty
    case miss
    case hit
    case sunk(shipSize: Int)
    
    var isHit: Bool {
        if case .hit = self { return true }
        return false
    }
    
    var isSunk: Bool {
        if case .sunk = self { return true }
        return false
    }
    
    var isMiss: Bool {
        if case .miss = self { return true }
        return false
    }
    
    var isBlocked: Bool {
        switch self {
        case .miss, .sunk: return true
        default: return false
        }
    }
}

struct SeaBattleGrid: Hashable, Sendable {
    var cells: [[CellState]]
    
    init() {
        cells = Array(repeating: Array(repeating: CellState.empty, count: 10), count: 10)
    }
    
    subscript(row: Int, col: Int) -> CellState {
        get { cells[row][col] }
        set { cells[row][col] = newValue }
    }
    
    subscript(pos: GridPosition) -> CellState {
        get { cells[pos.row][pos.col] }
        set { cells[pos.row][pos.col] = newValue }
    }
    
    var hits: [GridPosition] {
        var result: [GridPosition] = []
        for r in 0..<10 {
            for c in 0..<10 {
                if cells[r][c].isHit {
                    result.append(GridPosition(row: r, col: c))
                }
            }
        }
        return result
    }
    
    var misses: [GridPosition] {
        var result: [GridPosition] = []
        for r in 0..<10 {
            for c in 0..<10 {
                if cells[r][c].isMiss {
                    result.append(GridPosition(row: r, col: c))
                }
            }
        }
        return result
    }
}
