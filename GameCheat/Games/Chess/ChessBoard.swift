import Foundation

struct ChessBoard: Hashable, Sendable {
    private var squares: [[ChessPiece?]]
    private(set) var sideToMove: ChessColor

    init(squares: [[ChessPiece?]]? = nil, sideToMove: ChessColor = .white) {
        self.squares = squares ?? Self.standardSetup()
        self.sideToMove = sideToMove
    }

    static var standard: ChessBoard {
        ChessBoard()
    }

    subscript(_ square: ChessSquare) -> ChessPiece? {
        get { squares[square.row][square.col] }
        set { squares[square.row][square.col] = newValue }
    }

    func legalMoves() -> [ChessMove] {
        var allMoves: [ChessMove] = []

        for row in 0..<8 {
            for col in 0..<8 {
                let from = ChessSquare(row: row, col: col)
                guard let piece = self[from], piece.color == sideToMove else { continue }
                allMoves.append(contentsOf: moves(for: piece, from: from))
            }
        }

        return allMoves
    }

    func applying(_ move: ChessMove) -> ChessBoard {
        var next = self
        var moved = move.movedPiece

        if moved.kind == .pawn {
            if moved.color == .white && move.to.row == 0 {
                moved = ChessPiece(color: .white, kind: .queen)
            } else if moved.color == .black && move.to.row == 7 {
                moved = ChessPiece(color: .black, kind: .queen)
            }
        }

        next[move.to] = moved
        next[move.from] = nil
        next.sideToMove = sideToMove.opponent
        return next
    }

    private func moves(for piece: ChessPiece, from: ChessSquare) -> [ChessMove] {
        switch piece.kind {
        case .pawn:
            return pawnMoves(piece: piece, from: from)
        case .knight:
            return knightMoves(piece: piece, from: from)
        case .bishop:
            return slidingMoves(piece: piece, from: from, directions: [(-1, -1), (-1, 1), (1, -1), (1, 1)])
        case .rook:
            return slidingMoves(piece: piece, from: from, directions: [(-1, 0), (1, 0), (0, -1), (0, 1)])
        case .queen:
            return slidingMoves(piece: piece, from: from, directions: [
                (-1, -1), (-1, 1), (1, -1), (1, 1),
                (-1, 0), (1, 0), (0, -1), (0, 1)
            ])
        case .king:
            return kingMoves(piece: piece, from: from)
        }
    }

    private func pawnMoves(piece: ChessPiece, from: ChessSquare) -> [ChessMove] {
        var moves: [ChessMove] = []
        let direction = piece.color == .white ? -1 : 1
        let startRow = piece.color == .white ? 6 : 1

        let oneStep = ChessSquare(row: from.row + direction, col: from.col)
        if isValid(oneStep), self[oneStep] == nil {
            moves.append(
                ChessMove(from: from, to: oneStep, movedPiece: piece, capturedPiece: nil)
            )

            let twoStep = ChessSquare(row: from.row + (2 * direction), col: from.col)
            if from.row == startRow, isValid(twoStep), self[twoStep] == nil {
                moves.append(
                    ChessMove(from: from, to: twoStep, movedPiece: piece, capturedPiece: nil)
                )
            }
        }

        for dc in [-1, 1] {
            let capture = ChessSquare(row: from.row + direction, col: from.col + dc)
            guard isValid(capture), let target = self[capture], target.color != piece.color else { continue }
            moves.append(
                ChessMove(from: from, to: capture, movedPiece: piece, capturedPiece: target)
            )
        }

        return moves
    }

    private func knightMoves(piece: ChessPiece, from: ChessSquare) -> [ChessMove] {
        let jumps = [
            (-2, -1), (-2, 1), (-1, -2), (-1, 2),
            (1, -2), (1, 2), (2, -1), (2, 1)
        ]
        return jumps.compactMap { dr, dc in
            let to = ChessSquare(row: from.row + dr, col: from.col + dc)
            return makeMoveIfValid(from: from, to: to, piece: piece)
        }
    }

    private func kingMoves(piece: ChessPiece, from: ChessSquare) -> [ChessMove] {
        var result: [ChessMove] = []
        for dr in -1...1 {
            for dc in -1...1 {
                if dr == 0, dc == 0 { continue }
                let to = ChessSquare(row: from.row + dr, col: from.col + dc)
                if let move = makeMoveIfValid(from: from, to: to, piece: piece) {
                    result.append(move)
                }
            }
        }
        return result
    }

    private func slidingMoves(
        piece: ChessPiece,
        from: ChessSquare,
        directions: [(Int, Int)]
    ) -> [ChessMove] {
        var moves: [ChessMove] = []

        for (dr, dc) in directions {
            var row = from.row + dr
            var col = from.col + dc

            while ChessSquare.isValid(row: row, col: col) {
                let to = ChessSquare(row: row, col: col)
                if let target = self[to] {
                    if target.color != piece.color {
                        moves.append(
                            ChessMove(from: from, to: to, movedPiece: piece, capturedPiece: target)
                        )
                    }
                    break
                }

                moves.append(
                    ChessMove(from: from, to: to, movedPiece: piece, capturedPiece: nil)
                )
                row += dr
                col += dc
            }
        }

        return moves
    }

    private func makeMoveIfValid(from: ChessSquare, to: ChessSquare, piece: ChessPiece) -> ChessMove? {
        guard isValid(to) else { return nil }

        if let target = self[to] {
            guard target.color != piece.color else { return nil }
            return ChessMove(from: from, to: to, movedPiece: piece, capturedPiece: target)
        }

        return ChessMove(from: from, to: to, movedPiece: piece, capturedPiece: nil)
    }

    private func isValid(_ square: ChessSquare) -> Bool {
        ChessSquare.isValid(row: square.row, col: square.col)
    }

    private static func standardSetup() -> [[ChessPiece?]] {
        var board = Array(repeating: Array(repeating: Optional<ChessPiece>.none, count: 8), count: 8)

        let backRank: [ChessPieceKind] = [.rook, .knight, .bishop, .queen, .king, .bishop, .knight, .rook]
        for col in 0..<8 {
            board[0][col] = ChessPiece(color: .black, kind: backRank[col])
            board[1][col] = ChessPiece(color: .black, kind: .pawn)
            board[6][col] = ChessPiece(color: .white, kind: .pawn)
            board[7][col] = ChessPiece(color: .white, kind: backRank[col])
        }
        return board
    }
}
