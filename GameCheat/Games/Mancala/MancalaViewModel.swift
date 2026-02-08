import Foundation
import Observation

@MainActor
@Observable
final class MancalaViewModel {
    var state = MancalaState.initial
    var recommendedPit: Int?
    var isSolving = false
    var searchDepth = 8
    var analysisSummary: String?

    var winnerText: String? {
        guard state.isTerminal else { return nil }
        if let winner = state.winner {
            return winner == .one ? "Player 1 wins" : "Player 2 wins"
        }
        return "Draw"
    }

    var statusText: String {
        if let winnerText {
            return winnerText
        }
        return state.currentPlayer == .one ? "Player 1 to move" : "Player 2 to move"
    }

    func stones(relativePit: Int, player: Player) -> Int {
        let index = state.absolutePitIndex(relativeMove: relativePit, for: player)
        return state.pits[index]
    }

    func store(for player: Player) -> Int {
        player == .one ? state.pits[6] : state.pits[13]
    }

    func isPlayable(relativePit: Int, player: Player) -> Bool {
        player == state.currentPlayer && state.generateMoves().contains(relativePit)
    }

    func play(relativePit: Int) {
        guard !state.isTerminal, state.generateMoves().contains(relativePit) else { return }
        state = state.applying(relativePit)
        recommendedPit = nil
        analysisSummary = nil
    }

    func solve() {
        guard !state.isTerminal, !isSolving else { return }
        isSolving = true
        let snapshot = state
        let depth = searchDepth

        Task.detached(priority: .userInitiated) {
            let result = MinimaxSolver.bestMove(
                state: snapshot,
                config: SearchConfig(maxDepth: depth, maxTime: 1.2)
            )
            await MainActor.run {
                self.recommendedPit = result?.move
                if let result {
                    self.analysisSummary = "Depth \(result.depth), score \(Int(result.score)), nodes \(result.nodesEvaluated)"
                } else {
                    self.analysisSummary = "No legal move"
                }
                self.isSolving = false
            }
        }
    }

    func reset() {
        state = .initial
        recommendedPit = nil
        analysisSummary = nil
        isSolving = false
    }
}
