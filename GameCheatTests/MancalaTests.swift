import Testing
@testable import GameCheat

struct MancalaTests {
    @Test func initialStateHasSixMoves() {
        let state = MancalaState.initial
        #expect(state.generateMoves().count == 6)
    }

    @Test func applyingMoveAdvancesTurn() {
        let state = MancalaState.initial
        let next = state.applying(0)

        #expect(next.pits[0] == 0)
        #expect(next.currentPlayer == .two)
    }

    @Test func minimaxProducesRecommendedPit() {
        let result = MinimaxSolver.bestMove(
            state: MancalaState.initial,
            config: SearchConfig(maxDepth: 4, maxTime: 0.2)
        )
        #expect(result != nil)
    }
}
