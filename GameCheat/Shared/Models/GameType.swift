import Foundation

enum GameType: String, CaseIterable, Identifiable, Hashable {
    case wordHunt = "Word Hunt"
    case anagrams = "Anagrams"
    case fourInARow = "Four in a Row"
    case mancala = "Mancala"
    case chess = "Chess"
    case seaBattle = "Sea Battle"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var subtitle: String {
        switch self {
        case .wordHunt: return "Find all words"
        case .anagrams: return "Unscramble letters"
        case .fourInARow: return "Best next drop"
        case .mancala: return "Optimal pit choice"
        case .chess: return "Best next move"
        case .seaBattle: return "Where to fire"
        }
    }

    var iconName: String {
        switch self {
        case .wordHunt: return "character.magnify"
        case .anagrams: return "character.textbox"
        case .fourInARow: return "circle.grid.3x3.fill"
        case .mancala: return "oval"
        case .chess: return "crown.fill"
        case .seaBattle: return "scope"
        }
    }

    var isAvailable: Bool {
        switch self {
        case .wordHunt: return true
        case .anagrams: return true
        case .fourInARow: return true
        case .mancala: return true
        case .chess: return true
        case .seaBattle: return true
        }
    }
}
