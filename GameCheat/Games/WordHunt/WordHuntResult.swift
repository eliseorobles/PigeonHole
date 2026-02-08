import Foundation

struct WordHuntResult: Identifiable, Hashable {
    let id = UUID()
    let word: String
    let path: [GridPosition]

    var score: Int {
        switch word.count {
        case 3: return 100
        case 4: return 400
        case 5: return 800
        case 6: return 1400
        case 7: return 1800
        default:
            if word.count >= 8 {
                return 2200 + (word.count - 8) * 400
            }
            return 0
        }
    }
}
