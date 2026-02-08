import Testing
@testable import GameCheat

struct FourInARowTests {
    @Test func initialStateHasSevenMoves() {
        let state = FourInARowState.initial
        #expect(state.generateMoves().count == 7)
    }

    @Test func moveDropsPieceInLowestRow() {
        let state = FourInARowState.initial
        let next = state.applying(3)

        #expect(next.board[5][3] == .one)
        #expect(next.currentPlayer == .two)
    }

    @Test func minimaxProducesRecommendedColumn() {
        let result = MinimaxSolver.bestMove(
            state: FourInARowState.initial,
            config: SearchConfig(maxDepth: 3, maxTime: 0.2)
        )
        #expect(result != nil)
    }
}
