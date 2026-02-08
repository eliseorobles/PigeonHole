import Foundation

enum BattleMode: String, Sendable {
    case hunt = "Hunt"
    case target = "Target"
}

struct HuntTargetStrategy: Sendable {
    static func determineMode(grid: SeaBattleGrid) -> BattleMode {
        // If there are unsunk hits, we're in target mode
        for r in 0..<10 {
            for c in 0..<10 {
                if grid[r, c].isHit {
                    return .target
                }
            }
        }
        return .hunt
    }
    
    static func applyTargetModeBoost(probabilities: inout [[Double]], grid: SeaBattleGrid) {
        let mode = determineMode(grid: grid)
        guard mode == .target else { return }
        
        let hits = grid.hits
        let directions = [(-1, 0), (1, 0), (0, -1), (0, 1)]
        
        for hit in hits {
            for (dr, dc) in directions {
                let nr = hit.row + dr
                let nc = hit.col + dc
                guard nr >= 0 && nr < 10 && nc >= 0 && nc < 10 else { continue }
                if grid[nr, nc] == .empty {
                    probabilities[nr][nc] *= 2.0
                }
            }
        }
        
        // Re-normalize
        var maxVal = 0.0
        for r in 0..<10 {
            for c in 0..<10 {
                maxVal = max(maxVal, probabilities[r][c])
            }
        }
        if maxVal > 0 {
            for r in 0..<10 {
                for c in 0..<10 {
                    probabilities[r][c] /= maxVal
                }
            }
        }
    }
}
