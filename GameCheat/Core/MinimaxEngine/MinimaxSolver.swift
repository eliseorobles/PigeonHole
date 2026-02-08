import Foundation

struct SearchConfig: Sendable {
    var maxDepth: Int = 10
    var maxTime: TimeInterval? = 5.0
}

struct SearchResult<Move: Hashable & Sendable>: Sendable {
    let move: Move
    let score: Double
    let depth: Int
    let nodesEvaluated: Int
}

struct MinimaxSolver: Sendable {
    static func bestMove<S: GameState>(state: S, config: SearchConfig) -> SearchResult<S.Move>? {
        let moves = state.generateMoves()
        guard !moves.isEmpty else { return nil }

        let startTime = Date()
        var bestResult: SearchResult<S.Move>?

        for depth in 1...config.maxDepth {
            if let maxTime = config.maxTime, Date().timeIntervalSince(startTime) >= maxTime {
                break
            }

            var bestScore = -Double.infinity
            var bestMove = moves[0]
            var totalNodes = 0

            for move in moves {
                let newState = state.applying(move)
                var nodes = 0
                let score = -Self.alphabeta(
                    state: newState,
                    depth: depth - 1,
                    alpha: -Double.infinity,
                    beta: -(-bestScore),
                    maximizingForOriginal: state.currentPlayer,
                    nodes: &nodes,
                    startTime: startTime,
                    maxTime: config.maxTime
                )
                totalNodes += nodes

                if score > bestScore {
                    bestScore = score
                    bestMove = move
                }
            }

            bestResult = SearchResult(move: bestMove, score: bestScore, depth: depth, nodesEvaluated: totalNodes)

            if bestScore > 900000 || bestScore < -900000 {
                break
            }
        }

        return bestResult
    }

    private static func alphabeta<S: GameState>(
        state: S,
        depth: Int,
        alpha: Double,
        beta: Double,
        maximizingForOriginal: Player,
        nodes: inout Int,
        startTime: Date,
        maxTime: TimeInterval?
    ) -> Double {
        nodes += 1

        if depth == 0 || state.isTerminal {
            let eval = state.evaluate()
            return state.currentPlayer == maximizingForOriginal ? eval : -eval
        }

        if let maxTime = maxTime, Date().timeIntervalSince(startTime) >= maxTime {
            let eval = state.evaluate()
            return state.currentPlayer == maximizingForOriginal ? eval : -eval
        }

        var alpha = alpha
        let moves = state.generateMoves()

        for move in moves {
            let newState = state.applying(move)
            let score = -Self.alphabeta(
                state: newState,
                depth: depth - 1,
                alpha: -beta,
                beta: -alpha,
                maximizingForOriginal: maximizingForOriginal,
                nodes: &nodes,
                startTime: startTime,
                maxTime: maxTime
            )

            if score > alpha {
                alpha = score
            }
            if alpha >= beta {
                break
            }
        }

        return alpha
    }
}
