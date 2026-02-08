import Foundation

protocol ChessEngine: Sendable {
    func analyze(board: ChessBoard, skillLevel: Int, maxTime: TimeInterval) -> ChessMove?
}

struct CompositeChessEngine: ChessEngine {
    private let stockfish = StockfishEngine()
    private let fallback = StockfishFallbackEngine()

    func analyze(board: ChessBoard, skillLevel: Int, maxTime: TimeInterval) -> ChessMove? {
        if let stockfishMove = stockfish.analyze(board: board, skillLevel: skillLevel, maxTime: maxTime) {
            return stockfishMove
        }
        return fallback.analyze(board: board, skillLevel: skillLevel, maxTime: maxTime)
    }
}

struct StockfishEngine: ChessEngine {
    func analyze(board: ChessBoard, skillLevel: Int, maxTime: TimeInterval) -> ChessMove? {
        let legalMoves = board.legalMoves()
        guard !legalMoves.isEmpty else { return nil }

        let fen = board.fenForEngine()
        guard let uciMove = StockfishBridgeAdapter.bestMove(fen: fen, skillLevel: skillLevel, maxTime: maxTime) else {
            return nil
        }
        guard let mappedMove = board.move(fromUCI: uciMove) else { return nil }
        return legalMoves.contains(mappedMove) ? mappedMove : nil
    }
}

struct StockfishFallbackEngine: ChessEngine {
    func analyze(board: ChessBoard, skillLevel: Int, maxTime: TimeInterval) -> ChessMove? {
        let moves = board.legalMoves()
        guard !moves.isEmpty else { return nil }

        let searchDepth = depth(for: skillLevel)
        let deadline = Date().addingTimeInterval(maxTime)

        var bestMove = moves[0]
        var bestScore = -Double.infinity

        for move in moves {
            let child = board.applying(move)
            let score = -search(
                board: child,
                depth: searchDepth - 1,
                alpha: -Double.infinity,
                beta: Double.infinity,
                perspective: board.sideToMove,
                deadline: deadline
            )

            if score > bestScore {
                bestScore = score
                bestMove = move
            }
        }

        return bestMove
    }

    private func search(
        board: ChessBoard,
        depth: Int,
        alpha: Double,
        beta: Double,
        perspective: ChessColor,
        deadline: Date
    ) -> Double {
        if depth == 0 || Date() >= deadline {
            return evaluate(board: board, perspective: perspective)
        }

        let moves = board.legalMoves()
        if moves.isEmpty {
            return evaluate(board: board, perspective: perspective)
        }

        var alpha = alpha
        for move in moves {
            let child = board.applying(move)
            let score = -search(
                board: child,
                depth: depth - 1,
                alpha: -beta,
                beta: -alpha,
                perspective: perspective,
                deadline: deadline
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

    private func evaluate(board: ChessBoard, perspective: ChessColor) -> Double {
        var whiteScore = 0
        var blackScore = 0

        for row in 0..<8 {
            for col in 0..<8 {
                let square = ChessSquare(row: row, col: col)
                guard let piece = board[square] else { continue }
                if piece.color == .white {
                    whiteScore += piece.kind.materialValue
                } else {
                    blackScore += piece.kind.materialValue
                }
            }
        }

        let material = Double(whiteScore - blackScore)
        let mobilityWeight = board.sideToMove == .white ? 1.0 : -1.0
        let mobility = Double(board.legalMoves().count) * 0.05 * mobilityWeight
        let raw = material + mobility
        return perspective == .white ? raw : -raw
    }

    private func depth(for skillLevel: Int) -> Int {
        switch max(0, min(20, skillLevel)) {
        case 0...6:
            return 1
        case 7...13:
            return 2
        default:
            return 3
        }
    }
}

private enum StockfishBridgeAdapter {
    static func bestMove(fen: String, skillLevel: Int, maxTime: TimeInterval) -> String? {
        let clampedSkill = Int32(max(0, min(20, skillLevel)))
        let moveTimeMs = Int32(max(50, Int(maxTime * 1000)))
        var output = [CChar](repeating: 0, count: 16)

        let success = fen.withCString { fenPtr in
            gc_stockfish_bestmove(
                fenPtr,
                clampedSkill,
                moveTimeMs,
                &output,
                Int32(output.count)
            )
        }

        guard success == 1 else { return nil }

        let move = String(cString: output)
        return move.isEmpty ? nil : move
    }
}

private extension ChessBoard {
    func fenForEngine() -> String {
        "\(fenPiecePlacement()) \(sideToMove == .white ? "w" : "b") - - 0 1"
    }

    func move(fromUCI uci: String) -> ChessMove? {
        guard uci.count >= 4 else { return nil }
        let fromText = String(uci.prefix(2))
        let toText = String(uci.dropFirst(2).prefix(2))
        guard
            let from = ChessBoard.square(from: fromText),
            let to = ChessBoard.square(from: toText)
        else {
            return nil
        }
        return legalMoves().first { $0.from == from && $0.to == to }
    }

    private func fenPiecePlacement() -> String {
        var rows: [String] = []
        rows.reserveCapacity(8)

        for row in 0..<8 {
            var rowText = ""
            var emptyCount = 0

            for col in 0..<8 {
                let square = ChessSquare(row: row, col: col)
                guard let piece = self[square] else {
                    emptyCount += 1
                    continue
                }

                if emptyCount > 0 {
                    rowText.append("\(emptyCount)")
                    emptyCount = 0
                }

                rowText.append(fenChar(for: piece))
            }

            if emptyCount > 0 {
                rowText.append("\(emptyCount)")
            }
            rows.append(rowText)
        }

        return rows.joined(separator: "/")
    }

    private static func square(from coordinate: String) -> ChessSquare? {
        guard coordinate.count == 2 else { return nil }
        let chars = Array(coordinate.lowercased())
        guard let file = chars.first, let rank = chars.last else { return nil }
        guard let fileASCII = file.asciiValue, let aASCII = Character("a").asciiValue else { return nil }
        guard fileASCII >= aASCII && fileASCII <= aASCII + 7 else { return nil }
        guard let rankValue = Int(String(rank)), (1...8).contains(rankValue) else { return nil }
        let col = Int(fileASCII - aASCII)
        let row = 8 - rankValue
        return ChessSquare(row: row, col: col)
    }

    private func fenChar(for piece: ChessPiece) -> Character {
        let base: Character
        switch piece.kind {
        case .king: base = "k"
        case .queen: base = "q"
        case .rook: base = "r"
        case .bishop: base = "b"
        case .knight: base = "n"
        case .pawn: base = "p"
        }
        if piece.color == .white {
            return Character(String(base).uppercased())
        }
        return base
    }
}
