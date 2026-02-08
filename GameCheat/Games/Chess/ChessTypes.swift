import Foundation

enum ChessColor: String, CaseIterable, Hashable, Sendable {
    case white
    case black

    var opponent: ChessColor {
        self == .white ? .black : .white
    }

    var shortName: String {
        self == .white ? "W" : "B"
    }
}

enum ChessPieceKind: String, CaseIterable, Hashable, Sendable {
    case king
    case queen
    case rook
    case bishop
    case knight
    case pawn

    var notation: String {
        switch self {
        case .king: return "K"
        case .queen: return "Q"
        case .rook: return "R"
        case .bishop: return "B"
        case .knight: return "N"
        case .pawn: return "P"
        }
    }

    var materialValue: Int {
        switch self {
        case .pawn: return 100
        case .knight: return 320
        case .bishop: return 330
        case .rook: return 500
        case .queen: return 900
        case .king: return 20_000
        }
    }
}

struct ChessPiece: Hashable, Sendable {
    let color: ChessColor
    let kind: ChessPieceKind

    var code: String {
        "\(color.shortName)\(kind.notation)"
    }

    var displayName: String {
        "\(color == .white ? "White" : "Black") \(kindName)"
    }

    var symbol: String {
        switch (color, kind) {
        case (.white, .king): return "\u{2654}"
        case (.white, .queen): return "\u{2655}"
        case (.white, .rook): return "\u{2656}"
        case (.white, .bishop): return "\u{2657}"
        case (.white, .knight): return "\u{2658}"
        case (.white, .pawn): return "\u{2659}"
        case (.black, .king): return "\u{265A}"
        case (.black, .queen): return "\u{265B}"
        case (.black, .rook): return "\u{265C}"
        case (.black, .bishop): return "\u{265D}"
        case (.black, .knight): return "\u{265E}"
        case (.black, .pawn): return "\u{265F}"
        }
    }

    private var kindName: String {
        switch kind {
        case .king: return "King"
        case .queen: return "Queen"
        case .rook: return "Rook"
        case .bishop: return "Bishop"
        case .knight: return "Knight"
        case .pawn: return "Pawn"
        }
    }
}

struct ChessSquare: Hashable, Sendable, Identifiable {
    let row: Int
    let col: Int

    var id: String {
        "\(row)-\(col)"
    }

    var algebraic: String {
        let files = Array("abcdefgh")
        return "\(files[col])\(8 - row)"
    }

    static func isValid(row: Int, col: Int) -> Bool {
        (0..<8).contains(row) && (0..<8).contains(col)
    }
}

struct ChessMove: Hashable, Sendable, Identifiable {
    let from: ChessSquare
    let to: ChessSquare
    let movedPiece: ChessPiece
    let capturedPiece: ChessPiece?

    var id: String {
        "\(from.id)-\(to.id)"
    }

    var notation: String {
        if movedPiece.kind == .pawn {
            if capturedPiece != nil {
                return "\(from.algebraic.prefix(1))x\(to.algebraic)"
            }
            return to.algebraic
        }

        let capture = capturedPiece == nil ? "" : "x"
        return "\(movedPiece.kind.notation)\(capture)\(to.algebraic)"
    }
}
