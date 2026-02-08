import Foundation

struct ProbabilityCalculator: Sendable {
    static func calculate(grid: SeaBattleGrid, remainingShips: [Int]) -> [[Double]] {
        var counts = Array(repeating: Array(repeating: 0.0, count: 10), count: 10)
        
        for shipSize in remainingShips {
            // Try every horizontal placement
            for row in 0..<10 {
                for col in 0...(10 - shipSize) {
                    if canPlace(grid: grid, row: row, col: col, size: shipSize, horizontal: true) {
                        for i in 0..<shipSize {
                            counts[row][col + i] += 1
                        }
                    }
                }
            }
            // Try every vertical placement
            for row in 0...(10 - shipSize) {
                for col in 0..<10 {
                    if canPlace(grid: grid, row: row, col: col, size: shipSize, horizontal: false) {
                        for i in 0..<shipSize {
                            counts[row + i][col] += 1
                        }
                    }
                }
            }
        }
        
        // Zero out non-empty cells and normalize
        var maxVal = 0.0
        for r in 0..<10 {
            for c in 0..<10 {
                if grid[r, c] != .empty && !grid[r, c].isHit {
                    counts[r][c] = 0
                }
                // Hits should not be recommended as shots
                if grid[r, c].isHit {
                    counts[r][c] = 0
                }
                maxVal = max(maxVal, counts[r][c])
            }
        }
        
        // Normalize to 0.0-1.0
        if maxVal > 0 {
            for r in 0..<10 {
                for c in 0..<10 {
                    counts[r][c] /= maxVal
                }
            }
        }
        
        return counts
    }
    
    private static func canPlace(grid: SeaBattleGrid, row: Int, col: Int, size: Int, horizontal: Bool) -> Bool {
        for i in 0..<size {
            let r = horizontal ? row : row + i
            let c = horizontal ? col + i : col
            guard r < 10 && c < 10 else { return false }
            let cell = grid[r, c]
            // Can place on empty or hit cells (ship might be there), but not miss or sunk
            if cell.isBlocked {
                return false
            }
        }
        return true
    }
}
