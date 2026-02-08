import Foundation
import Observation

@MainActor
@Observable
final class ChessViewModel {
    var board = ChessBoard.standard
    var selectedSquare: ChessSquare?
    var bestMove: ChessMove?
    var skillLevel = 10
    var isAnalyzing = false

    private let engine = CompositeChessEngine()

    var sideToMoveLabel: String {
        board.sideToMove == .white ? "White to move" : "Black to move"
    }

    var interactionHint: String {
        if isAnalyzing {
            return "Analyzing board..."
        }
        if selectedSquare != nil {
            return "Tap a highlighted square to move"
        }
        return "Tap one of your pieces to begin"
    }

    var nextStepText: String {
        if isAnalyzing {
            return "Next: wait for Stockfish to finish."
        }
        if let bestMove {
            return "Next: tap Play Suggested Move to apply \(bestMove.notation), or make any legal move manually."
        }
        if selectedSquare != nil {
            return "Next: tap one highlighted square to complete your move."
        }
        return "Next: tap a piece to move it, or tap Get Best Move for a hint."
    }

    var selectedPieceLabel: String? {
        guard let selectedSquare, let piece = board[selectedSquare] else {
            return nil
        }
        return "Selected: \(piece.displayName) on \(selectedSquare.algebraic)"
    }

    var bestMoveLabel: String {
        guard let bestMove else { return "No line calculated" }
        return "Best move: \(bestMove.notation)"
    }

    func pieceCode(at square: ChessSquare) -> String {
        board[square]?.code ?? ""
    }

    func piece(at square: ChessSquare) -> ChessPiece? {
        board[square]
    }

    func isSelected(_ square: ChessSquare) -> Bool {
        selectedSquare == square
    }

    func isLegalTarget(_ square: ChessSquare) -> Bool {
        guard let selectedSquare else { return false }
        return board.legalMoves().contains { $0.from == selectedSquare && $0.to == square }
    }

    func isBestMoveSquare(_ square: ChessSquare) -> Bool {
        guard let bestMove else { return false }
        return bestMove.from == square || bestMove.to == square
    }

    func tap(square: ChessSquare) {
        guard !isAnalyzing else { return }

        if let selectedSquare,
           let chosenMove = board
            .legalMoves()
            .first(where: { $0.from == selectedSquare && $0.to == square }) {
            board = board.applying(chosenMove)
            self.selectedSquare = nil
            bestMove = nil
            AppTheme.impactMedium()
            analyze()
            return
        }

        guard let piece = board[square], piece.color == board.sideToMove else {
            selectedSquare = nil
            return
        }
        selectedSquare = square
        AppTheme.impactLight()
    }

    func analyze() {
        guard !isAnalyzing else { return }
        isAnalyzing = true
        bestMove = nil

        let snapshot = board
        let skill = skillLevel
        let engine = self.engine

        Task.detached(priority: .userInitiated) {
            let move = engine.analyze(board: snapshot, skillLevel: skill, maxTime: 0.8)
            await MainActor.run {
                self.bestMove = move
                self.isAnalyzing = false
            }
        }
    }

    func applyBestMove() {
        guard let bestMove else { return }
        board = board.applying(bestMove)
        self.bestMove = nil
        selectedSquare = nil
        AppTheme.impactMedium()
        analyze()
    }

    func reset() {
        board = .standard
        selectedSquare = nil
        bestMove = nil
        isAnalyzing = false
        skillLevel = 10
    }
}
