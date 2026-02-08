import Foundation

final class TrieNode {
    var children: [TrieNode?] = Array(repeating: nil, count: 26)
    var isWord: Bool = false

    static func index(for character: Character) -> Int? {
        guard let ascii = character.asciiValue else { return nil }
        let idx = Int(ascii) - Int(Character("a").asciiValue!)
        guard idx >= 0 && idx < 26 else { return nil }
        return idx
    }
}
