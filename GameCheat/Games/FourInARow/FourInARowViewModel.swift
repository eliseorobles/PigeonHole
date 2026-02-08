import Foundation
import Observation

@MainActor
@Observable
final class FourInARowViewModel {
    var state = FourInARowState.initial
    var recommendedColumn: Int?
    var isSolving = false
    var searchDepth = 5
    var analysisSummary: String?

    var board: [[Player?]] {
        state.board
    }

    var currentPlayerName: String {
        state.currentPlayer == .one ? "Red" : "Yellow"
    }

    var winnerText: String? {
        if let winner = state.winner {
            return winner == .one ? "Red wins" : "Yellow wins"
        }
        if state.generateMoves().isEmpty {
            return "Draw"
        }
        return nil
    }

    var canPlay: Bool {
        !state.isTerminal && !isSolving
    }

    func drop(in column: Int) {
        guard canPlay, state.generateMoves().contains(column) else { return }
        state = state.applying(column)
        recommendedColumn = nil
        analysisSummary = nil
    }

    func solve() {
        guard canPlay else { return }
        isSolving = true
        let snapshot = state
        let depth = searchDepth

        Task.detached(priority: .userInitiated) {
            let result = MinimaxSolver.bestMove(
                state: snapshot,
                config: SearchConfig(maxDepth: depth, maxTime: 1.0)
            )

            await MainActor.run {
                self.recommendedColumn = result?.move
                if let result {
                    self.analysisSummary = "Depth \(result.depth), score \(Int(result.score)), nodes \(result.nodesEvaluated)"
                } else {
                    self.analysisSummary = "No legal moves"
                }
                self.isSolving = false
            }
        }
    }

    func reset() {
        state = .initial
        recommendedColumn = nil
        analysisSummary = nil
        isSolving = false
    }
}
