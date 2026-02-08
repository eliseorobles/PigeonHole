import Foundation

struct WordHuntSolver: Sendable {
    static func solve(grid: [[Character]], dictionary: WordDictionary) -> [WordHuntResult] {
        let rows = grid.count
        guard rows == 4 else { return [] }
        let cols = grid[0].count
        guard cols == 4 else { return [] }

        var foundWords: [String: [GridPosition]] = [:]

        for row in 0..<rows {
            for col in 0..<cols {
                var visited: UInt16 = 0
                let bit = row * cols + col
                visited |= (1 << bit)
                let startPos = GridPosition(row: row, col: col)
                dfs(
                    grid: grid,
                    row: row,
                    col: col,
                    path: [startPos],
                    current: String(grid[row][col]),
                    visited: visited,
                    dictionary: dictionary,
                    found: &foundWords
                )
            }
        }

        return foundWords.map { word, path in
            WordHuntResult(word: word, path: path)
        }.sorted { a, b in
            if a.word.count != b.word.count {
                return a.word.count < b.word.count
            }
            return a.word < b.word
        }
    }

    private static func dfs(
        grid: [[Character]],
        row: Int,
        col: Int,
        path: [GridPosition],
        current: String,
        visited: UInt16,
        dictionary: WordDictionary,
        found: inout [String: [GridPosition]]
    ) {
        let lower = current.lowercased()

        guard dictionary.hasPrefix(lower) else { return }

        if lower.count >= 3 && dictionary.isWord(lower) {
            if found[lower] == nil || found[lower]!.count > path.count {
                found[lower] = path
            }
        }

        let directions = [(-1, -1), (-1, 0), (-1, 1),
                          (0, -1),           (0, 1),
                          (1, -1),  (1, 0),  (1, 1)]

        for (dr, dc) in directions {
            let nr = row + dr
            let nc = col + dc
            guard nr >= 0 && nr < 4 && nc >= 0 && nc < 4 else { continue }
            let bit = nr * 4 + nc
            guard visited & (1 << bit) == 0 else { continue }

            var newVisited = visited
            newVisited |= (1 << bit)
            let newPos = GridPosition(row: nr, col: nc)

            dfs(
                grid: grid,
                row: nr,
                col: nc,
                path: path + [newPos],
                current: current + String(grid[nr][nc]),
                visited: newVisited,
                dictionary: dictionary,
                found: &found
            )
        }
    }
}
