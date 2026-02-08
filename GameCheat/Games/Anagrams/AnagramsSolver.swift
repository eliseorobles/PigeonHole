import Foundation

struct AnagramsSolver: Sendable {
    static func solve(letters: String, dictionary: WordDictionary, minLength: Int = 3) -> [AnagramsResult] {
        let trieRoot = dictionary.trieRoot

        var frequency: [Int] = Array(repeating: 0, count: 26)
        for char in letters.lowercased() {
            if let idx = TrieNode.index(for: char) {
                frequency[idx] += 1
            }
        }

        var found = Set<String>()
        var current: [Character] = []

        func dfs(node: TrieNode) {
            if node.isWord && current.count >= minLength {
                found.insert(String(current))
            }

            for i in 0..<26 where frequency[i] > 0 {
                guard let child = node.children[i] else { continue }
                frequency[i] -= 1
                current.append(Character(UnicodeScalar(Int(Character("a").asciiValue!) + i)!))
                dfs(node: child)
                current.removeLast()
                frequency[i] += 1
            }
        }

        dfs(node: trieRoot)

        return found.map { AnagramsResult(word: $0) }
            .sorted { a, b in
                if a.word.count != b.word.count { return a.word.count > b.word.count }
                return a.word < b.word
            }
    }
}
