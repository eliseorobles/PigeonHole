import Foundation
import Observation

@MainActor
@Observable
final class SeaBattleViewModel {
    var grid = SeaBattleGrid()
    var remainingShips: [Int] = [5, 4, 3, 3, 2]
    var probabilities: [[Double]] = Array(repeating: Array(repeating: 0.0, count: 10), count: 10)
    
    var mode: BattleMode {
        HuntTargetStrategy.determineMode(grid: grid)
    }
    
    var recommendedShot: GridPosition? {
        var bestPos: GridPosition?
        var bestProb = 0.0
        for r in 0..<10 {
            for c in 0..<10 {
                if probabilities[r][c] > bestProb {
                    bestProb = probabilities[r][c]
                    bestPos = GridPosition(row: r, col: c)
                }
            }
        }
        return bestPos
    }
    
    init() {
        recalculate()
    }

    func setCellState(at pos: GridPosition, to state: CellState) {
        grid[pos] = state
        recalculate()
    }

    func cycleCellState(at pos: GridPosition) {
        switch grid[pos] {
        case .empty:
            grid[pos] = .miss
        case .miss:
            grid[pos] = .hit
        case .hit:
            grid[pos] = .empty
        case .sunk:
            grid[pos] = .empty
        }
        recalculate()
    }

    func probability(at pos: GridPosition) -> Double {
        probabilities[pos.row][pos.col]
    }

    func canMarkSunk(shipSize: Int) -> Bool {
        remainingShips.contains(shipSize) && grid.hits.count >= shipSize
    }
    
    func markShipAsSunk(at positions: [GridPosition], shipSize: Int) {
        for pos in positions {
            grid[pos] = .sunk(shipSize: shipSize)
        }
        if let idx = remainingShips.firstIndex(of: shipSize) {
            remainingShips.remove(at: idx)
        }
        recalculate()
    }
    
    func markSunkBySize(_ shipSize: Int) {
        // Find connected hit cells that match the ship size
        // For simplicity, just mark individual hits as sunk and remove from fleet
        let hits = grid.hits
        if hits.count >= shipSize {
            // Mark first N hits as sunk
            for i in 0..<min(shipSize, hits.count) {
                grid[hits[i]] = .sunk(shipSize: shipSize)
            }
        }
        if let idx = remainingShips.firstIndex(of: shipSize) {
            remainingShips.remove(at: idx)
        }
        recalculate()
    }
    
    func resetGrid() {
        grid = SeaBattleGrid()
        remainingShips = [5, 4, 3, 3, 2]
        recalculate()
    }
    
    func setRemainingShips(_ ships: [Int]) {
        remainingShips = ships
        recalculate()
    }
    
    private func recalculate() {
        probabilities = ProbabilityCalculator.calculate(grid: grid, remainingShips: remainingShips)
        HuntTargetStrategy.applyTargetModeBoost(probabilities: &probabilities, grid: grid)
    }
}
