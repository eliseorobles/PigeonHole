import Testing
@testable import GameCheat

struct ChessBoardTests {
    @Test func standardBoardHasLegalMoves() {
        let board = ChessBoard.standard
        #expect(!board.legalMoves().isEmpty)
    }

    @Test func applyingMoveUpdatesBoardAndTurn() {
        let board = ChessBoard.standard
        let move = board.legalMoves().first!
        let next = board.applying(move)

        #expect(next[move.from] == nil)
        #expect(next[move.to] != nil)
        #expect(next.sideToMove == .black)
    }

    @Test func fallbackEngineReturnsMove() {
        let board = ChessBoard.standard
        let engine = StockfishFallbackEngine()
        let bestMove = engine.analyze(board: board, skillLevel: 10, maxTime: 0.1)
        #expect(bestMove != nil)
    }

    @Test func stockfishEngineReturnsMove() {
        let board = ChessBoard.standard
        let engine = StockfishEngine()
        let bestMove = engine.analyze(board: board, skillLevel: 10, maxTime: 0.2)
        #expect(bestMove != nil)
    }

    @Test func compositeEngineReturnsMove() {
        let board = ChessBoard.standard
        let engine = CompositeChessEngine()
        let bestMove = engine.analyze(board: board, skillLevel: 10, maxTime: 0.2)
        #expect(bestMove != nil)
    }
}
