import Foundation

struct FourInARowState: GameState, Hashable {
    typealias Move = Int

    static let rows = 6
    static let columns = 7

    var board: [[Player?]]
    var currentPlayer: Player

    init(board: [[Player?]]? = nil, currentPlayer: Player = .one) {
        self.board = board ?? Array(
            repeating: Array(repeating: nil, count: Self.columns),
            count: Self.rows
        )
        self.currentPlayer = currentPlayer
    }

    static var initial: FourInARowState {
        FourInARowState()
    }

    var winner: Player? {
        for row in 0..<Self.rows {
            for col in 0..<Self.columns {
                guard let piece = board[row][col] else { continue }

                if hasLine(of: piece, row: row, col: col, dr: 0, dc: 1) ||
                    hasLine(of: piece, row: row, col: col, dr: 1, dc: 0) ||
                    hasLine(of: piece, row: row, col: col, dr: 1, dc: 1) ||
                    hasLine(of: piece, row: row, col: col, dr: 1, dc: -1) {
                    return piece
                }
            }
        }
        return nil
    }

    var isTerminal: Bool {
        winner != nil || generateMoves().isEmpty
    }

    func generateMoves() -> [Int] {
        (0..<Self.columns).filter { board[0][$0] == nil }
    }

    func applying(_ move: Int) -> FourInARowState {
        guard generateMoves().contains(move) else { return self }

        var newBoard = board
        for row in stride(from: Self.rows - 1, through: 0, by: -1) {
            if newBoard[row][move] == nil {
                newBoard[row][move] = currentPlayer
                break
            }
        }

        return FourInARowState(board: newBoard, currentPlayer: currentPlayer.opponent)
    }

    func evaluate() -> Double {
        if let winner {
            return winner == currentPlayer ? 100_000 : -100_000
        }
        if generateMoves().isEmpty {
            return 0
        }

        let oneScore = positionalScore(for: .one)
        let twoScore = positionalScore(for: .two)
        let raw = Double(oneScore - twoScore)
        return currentPlayer == .one ? raw : -raw
    }

    private func hasLine(of player: Player, row: Int, col: Int, dr: Int, dc: Int) -> Bool {
        for step in 0..<4 {
            let nr = row + (dr * step)
            let nc = col + (dc * step)
            guard nr >= 0, nr < Self.rows, nc >= 0, nc < Self.columns else {
                return false
            }
            if board[nr][nc] != player {
                return false
            }
        }
        return true
    }

    private func positionalScore(for player: Player) -> Int {
        var score = 0

        for row in 0..<Self.rows {
            if board[row][Self.columns / 2] == player {
                score += 3
            }
        }

        for row in 0..<Self.rows {
            for col in 0..<(Self.columns - 3) {
                let window = [board[row][col], board[row][col + 1], board[row][col + 2], board[row][col + 3]]
                score += windowScore(window, for: player)
            }
        }

        for row in 0..<(Self.rows - 3) {
            for col in 0..<Self.columns {
                let window = [board[row][col], board[row + 1][col], board[row + 2][col], board[row + 3][col]]
                score += windowScore(window, for: player)
            }
        }

        for row in 0..<(Self.rows - 3) {
            for col in 0..<(Self.columns - 3) {
                let window = [board[row][col], board[row + 1][col + 1], board[row + 2][col + 2], board[row + 3][col + 3]]
                score += windowScore(window, for: player)
            }
        }

        for row in 0..<(Self.rows - 3) {
            for col in 3..<Self.columns {
                let window = [board[row][col], board[row + 1][col - 1], board[row + 2][col - 2], board[row + 3][col - 3]]
                score += windowScore(window, for: player)
            }
        }

        return score
    }

    private func windowScore(_ window: [Player?], for player: Player) -> Int {
        let ownCount = window.filter { $0 == player }.count
        let emptyCount = window.filter { $0 == nil }.count
        let opponentCount = window.filter { $0 == player.opponent }.count

        if ownCount == 4 { return 1000 }
        if ownCount == 3 && emptyCount == 1 { return 15 }
        if ownCount == 2 && emptyCount == 2 { return 4 }
        if opponentCount == 3 && emptyCount == 1 { return -12 }
        return 0
    }
}
