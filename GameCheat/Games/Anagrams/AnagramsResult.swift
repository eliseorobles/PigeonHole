import Foundation

struct AnagramsResult: Identifiable, Hashable {
    let id = UUID()
    let word: String

    func hash(into hasher: inout Hasher) {
        hasher.combine(word)
    }

    static func == (lhs: AnagramsResult, rhs: AnagramsResult) -> Bool {
        lhs.word == rhs.word
    }
}
