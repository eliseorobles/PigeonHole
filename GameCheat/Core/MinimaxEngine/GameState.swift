import Foundation

enum Player: String, CaseIterable, Hashable, Sendable {
    case one
    case two

    var opponent: Player {
        switch self {
        case .one: .two
        case .two: .one
        }
    }
}

protocol GameState: Sendable {
    associatedtype Move: Hashable & Sendable

    var currentPlayer: Player { get }
    var isTerminal: Bool { get }

    func generateMoves() -> [Move]
    func applying(_ move: Move) -> Self
    func evaluate() -> Double
}
